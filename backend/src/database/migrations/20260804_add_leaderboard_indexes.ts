import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.raw(
    'CREATE INDEX IF NOT EXISTS idx_user_sport_wins_losses ON user_sport_stats (sport, wins DESC, losses ASC);'
  );
  await knex.schema.raw(
    'CREATE INDEX IF NOT EXISTS idx_user_sport_stats_global_wins ON user_sport_stats (wins DESC, losses ASC);'
  );
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.raw('DROP INDEX IF EXISTS idx_user_sport_wins_losses;');
  await knex.schema.raw('DROP INDEX IF EXISTS idx_user_sport_stats_global_wins;');
}
