import courtRepository, { ICourtRow, ICreateCourtPayload } from '../repositories/court-repository';

interface OverpassElement {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

export class CourtService {
  private static readonly OVERPASS_ENDPOINTS = [
    'https://overpass-api.de/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  /**
   * Fetch nearby courts filtered by sport and radius.
   * Auto-triggers background OSM sync if local database has sparse coverage.
   */
  async getNearbyCourts(params: {
    latitude: number;
    longitude: number;
    radiusKm?: number;
    sport?: string;
    search?: string;
  }): Promise<ICourtRow[]> {
    try {
      const radiusKm = params.radiusKm || 20;

      // 1. Check local indexed PostgreSQL database
      const courts = await courtRepository.findNearby({
        latitude: params.latitude,
        longitude: params.longitude,
        radiusKm,
        sport: params.sport,
        search: params.search,
        limit: 50,
      });

      return courts;
    } catch (err) {
      console.error('[CourtService getNearbyCourts Error]:', err);
      throw err;
    }
  }

  /**
   * Sync courts from OpenStreetMap using Overpass QL API
   */
  async syncFromOpenStreetMap(
    lat: number,
    lng: number,
    radiusKm: number = 15,
    sportFilter?: string
  ): Promise<number> {
    try {
      const radiusMeters = Math.min(Math.round(radiusKm * 1000), 25000); // Cap at 25km radius

      // Target supported sports in Pulse
      let sportRegex = 'tennis|pickleball|badminton|table_tennis';
      if (sportFilter && sportFilter.toLowerCase() !== 'all') {
        const s = sportFilter.toLowerCase().trim();
        if (s === 'pickleball' || s === 'tennis' || s === 'badminton' || s === 'table_tennis') {
          sportRegex = s;
        }
      }

      const overpassQuery = `
        [out:json][timeout:15];
        (
          node["leisure"~"pitch|sports_centre"]["sport"~"${sportRegex}"](around:${radiusMeters},${lat},${lng});
          way["leisure"~"pitch|sports_centre"]["sport"~"${sportRegex}"](around:${radiusMeters},${lat},${lng});
        );
        out center tags;
      `;

      let elements: OverpassElement[] = [];
      let lastError: any = null;

      for (const endpoint of CourtService.OVERPASS_ENDPOINTS) {
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 12000);

          const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'PulseSportsApp/1.0',
            },
            body: `data=${encodeURIComponent(overpassQuery)}`,
            signal: controller.signal,
          });

          clearTimeout(timeoutId);

          if (response.ok) {
            const data: any = await response.json();
            elements = data.elements || [];
            break; // Success, exit endpoint loop
          }
        } catch (fetchErr) {
          lastError = fetchErr;
          console.error(`[CourtService Endpoint ${endpoint} Failed]:`, fetchErr);
        }
      }

      if (elements.length === 0 && lastError) {
        throw lastError;
      }

      let upsertCount = 0;

      for (const elem of elements) {
        const tags = elem.tags || {};
        const coords = elem.center || { lat: elem.lat || 0, lon: elem.lon || 0 };

        if (!coords.lat || !coords.lon) continue;

        // Determine sports
        const rawSport = (tags.sport || '').toLowerCase();
        const matchedSports: string[] = [];
        if (rawSport.includes('pickleball')) matchedSports.push('pickleball');
        if (rawSport.includes('tennis')) matchedSports.push('tennis');
        if (rawSport.includes('badminton')) matchedSports.push('badminton');
        if (rawSport.includes('table_tennis')) matchedSports.push('table_tennis');

        if (matchedSports.length === 0) {
          matchedSports.push('pickleball');
        }

        // Format venue name
        let courtName = tags.name || tags['name:en'] || '';
        if (!courtName) {
          const mainSport = matchedSports[0].charAt(0).toUpperCase() + matchedSports[0].slice(1);
          courtName = `${mainSport} Court`;
          if (tags['addr:street']) {
            courtName += ` at ${tags['addr:street']}`;
          }
        }

        const addressParts = [
          tags['addr:housenumber'],
          tags['addr:street'],
          tags['addr:suburb'] || tags['addr:district'],
        ].filter(Boolean);

        const address = addressParts.length > 0 
          ? addressParts.join(' ') 
          : (tags['addr:full'] || tags['description'] || null);

        const city = tags['addr:city'] || tags['addr:province'] || null;

        const payload: ICreateCourtPayload = {
          osm_id: `osm_${elem.type}_${elem.id}`,
          name: courtName,
          address,
          city,
          latitude: coords.lat,
          longitude: coords.lon,
          sports: matchedSports,
          surface: tags.surface || null,
          has_lighting: tags.lit === 'yes',
          is_indoor: tags.indoor === 'yes',
          access_type: tags.access || 'public',
          is_verified: true,
        };

        await courtRepository.upsertFromOsm(payload);
        upsertCount++;
      }

      return upsertCount;
    } catch (err) {
      console.error('[CourtService syncFromOpenStreetMap Error]:', err);
      throw err;
    }
  }

  /**
   * Allow users to suggest/create a community court
   */
  async createCourt(userId: string | null, payload: {
    name: string;
    address?: string;
    city?: string;
    latitude: number;
    longitude: number;
    sports: string[];
    surface?: string;
    has_lighting?: boolean;
    is_indoor?: boolean;
    access_type?: string;
    image_url?: string;
  }): Promise<ICourtRow> {
    try {
      if (!payload.name || payload.name.trim().length === 0) {
        throw new Error('Court name is required');
      }
      if (payload.latitude == null || payload.longitude == null) {
        throw new Error('Latitude and longitude are required');
      }

      const court = await courtRepository.createCourt({
        ...payload,
        is_verified: true,
        created_by: userId,
      });

      return court;
    } catch (err) {
      console.error('[CourtService createCourt Error]:', err);
      throw err;
    }
  }

  /**
   * Get reviews and rating statistics for a court
   */
  async getCourtReviews(courtId: string, userId?: string): Promise<{
    courtId: string;
    likesCount: number;
    dislikesCount: number;
    totalVotes: number;
    recommendationPercent: number;
    userVote?: boolean | null;
    reviews: any[];
  }> {
    try {
      const votes = await courtRepository.getCourtReviews(courtId);
      const comments = await courtRepository.getCourtComments(courtId);
      const likesCount = votes.filter((r) => r.is_liked).length;
      const dislikesCount = votes.filter((r) => !r.is_liked).length;
      const totalVotes = likesCount + dislikesCount;
      const recommendationPercent = totalVotes > 0 ? Math.round((likesCount / totalVotes) * 100) : 0;

      let userVote: boolean | null = null;
      if (userId) {
        const userVoteRecord = votes.find((r) => r.user_id === userId);
        if (userVoteRecord) {
          userVote = userVoteRecord.is_liked;
        }
      }

      // Format comments list as reviews for frontend compatibility
      const formattedComments = comments.map((c) => {
        const authorVote = votes.find((v) => v.user_id === c.user_id);
        return {
          id: c.id,
          court_id: c.court_id,
          user_id: c.user_id,
          user_name: c.user_name || 'Pulse Player',
          user_avatar: c.user_avatar,
          comment: c.comment,
          is_liked: authorVote ? authorVote.is_liked : true,
          created_at: c.created_at,
          updated_at: c.updated_at,
        };
      });

      return {
        courtId,
        likesCount,
        dislikesCount,
        totalVotes,
        recommendationPercent,
        userVote,
        reviews: formattedComments,
      };
    } catch (err) {
      console.error('[CourtService getCourtReviews Error]:', err);
      throw err;
    }
  }

  /**
   * Submit or update a court review/vote
   */
  async submitReview(
    courtId: string,
    userId: string,
    isLiked?: boolean,
    comment?: string | null
  ): Promise<any> {
    try {
      if (!courtId) {
        throw new Error('Court ID is required');
      }
      if (!userId) {
        throw new Error('User ID is required');
      }

      let cleanComment = comment ? comment.trim() : null;
      if (cleanComment && cleanComment.length > 500) {
        cleanComment = cleanComment.slice(0, 500);
      }

      const reviewResult = await courtRepository.upsertReview(courtId, userId, isLiked, cleanComment);
      const courtStats = await this.getCourtReviews(courtId, userId);

      return {
        ...reviewResult,
        likesCount: courtStats.likesCount,
        dislikesCount: courtStats.dislikesCount,
        totalVotes: courtStats.totalVotes,
        recommendationPercent: courtStats.recommendationPercent,
        userVote: courtStats.userVote,
      };
    } catch (err) {
      console.error('[CourtService submitReview Error]:', err);
      throw err;
    }
  }

  /**
   * Delete a court review
   */
  async deleteReview(courtId: string, userId: string): Promise<boolean> {
    try {
      return await courtRepository.deleteReview(courtId, userId);
    } catch (err) {
      console.error('[CourtService deleteReview Error]:', err);
      throw err;
    }
  }
}

export default new CourtService();
