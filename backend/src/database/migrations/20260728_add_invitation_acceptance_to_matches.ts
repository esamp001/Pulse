import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.boolean('player2_accepted').notNullable().defaultTo(false);
    table.boolean('scorer_accepted').notNullable().defaultTo(false);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropColumn('player2_accepted');
    table.dropColumn('scorer_accepted');
  });
}
