import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.uuid('court_id').nullable().references('id').inTable('courts').onDelete('SET NULL');

    // Mandatory indexes per project rules
    table.index(['court_id']);
    table.index(['status', 'sport']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropIndex(['court_id']);
    table.dropIndex(['status', 'sport']);
    table.dropColumn('court_id');
  });
}
