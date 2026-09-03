import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('court_reviews', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('court_id').notNullable().references('id').inTable('courts').onDelete('CASCADE');
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.boolean('is_liked').notNullable().defaultTo(true); // true = Like/Recommend, false = Dislike
    table.text('comment').nullable();
    table.timestamps(true, true);

    // One review/rating per player per court (can be updated)
    table.unique(['court_id', 'user_id']);

    // Mandatory indexes per project rules
    table.index(['court_id']);
    table.index(['user_id']);
    table.index(['is_liked']);
    table.index(['created_at']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('court_reviews');
}
