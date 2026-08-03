import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // 1. Backfill existing user ratings and W/L stats into user_sport_stats table
  const users = await knex('users').select('id', 'rating', 'wins', 'losses', 'primary_sport');

  for (const user of users) {
    const sportKey = (user.primary_sport || 'pickleball').toLowerCase().trim();
    const existing = await knex('user_sport_stats')
      .where({ user_id: user.id, sport: sportKey })
      .first();

    if (!existing) {
      await knex('user_sport_stats').insert({
        user_id: user.id,
        sport: sportKey,
        rating: user.rating || 1200,
        wins: user.wins || 0,
        losses: user.losses || 0,
        is_primary: true,
        created_at: new Date(),
        updated_at: new Date(),
      });
    }
  }

  // 2. Drop legacy columns rating, wins, losses from users table
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('rating');
    table.dropColumn('wins');
    table.dropColumn('losses');
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.integer('rating').notNullable().defaultTo(1200);
    table.integer('wins').notNullable().defaultTo(0);
    table.integer('losses').notNullable().defaultTo(0);
  });
}
