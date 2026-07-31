export interface EloResult {
  winnerNewRating: number;
  loserNewRating: number;
  ratingChange: number;
}

/**
 * Calculates updated Elo ratings for a winner and loser using standard Elo expected win probability.
 * @param winnerRating Current rating of the winning player
 * @param loserRating Current rating of the losing player
 * @param kFactor Rating volatility factor (default: 32)
 * @returns EloResult containing new ratings and the calculated rating change points
 */
export function calculateElo(winnerRating: number, loserRating: number, kFactor: number = 32): EloResult {
  // Calculate expected win probability for winner (value between 0.0 and 1.0)
  const expectedWinner = 1 / (1 + Math.pow(10, (loserRating - winnerRating) / 400));

  // Points exchanged = K * (Actual Score - Expected Score)
  const ratingChange = Math.max(1, Math.round(kFactor * (1 - expectedWinner)));

  return {
    winnerNewRating: winnerRating + ratingChange,
    loserNewRating: Math.max(100, loserRating - ratingChange), // Enforces a minimum rating floor of 100
    ratingChange,
  };
}
