import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('user_sport_stats', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('sport', 50).notNullable();
    table.integer('rating').notNullable().defaultTo(1200);
    table.integer('wins').notNullable().defaultTo(0);
    table.integer('losses').notNullable().defaultTo(0);
    table.boolean('is_primary').notNullable().defaultTo(false);
    table.timestamps(true, true);

    table.unique(['user_id', 'sport']);
    table.index(['user_id', 'sport']);
  });

  await knex.schema.raw(
    'CREATE INDEX idx_user_sport_rating ON user_sport_stats (sport, rating DESC);'
  );
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('user_sport_stats');
}
 