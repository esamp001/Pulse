import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('court_comments', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('court_id').notNullable().references('id').inTable('courts').onDelete('CASCADE');
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.text('comment').notNullable();
    table.timestamps(true, true);

    // Mandatory indexes per project rules
    table.index(['court_id']);
    table.index(['user_id']);
    table.index(['created_at']);
  });

  // Migrate existing comments from court_reviews into court_comments table
  const hasCourtReviews = await knex.schema.hasTable('court_reviews');
  if (hasCourtReviews) {
    await knex.raw(`
      INSERT INTO court_comments (court_id, user_id, comment, created_at, updated_at)
      SELECT court_id, user_id, comment, created_at, updated_at
      FROM court_reviews
      WHERE comment IS NOT NULL AND TRIM(comment) != '';
    `);
  }
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('court_comments');
}
