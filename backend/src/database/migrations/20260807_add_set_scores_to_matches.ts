import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.integer('player1_sets_won').notNullable().defaultTo(0);
    table.integer('player2_sets_won').notNullable().defaultTo(0);
    table.text('set_scores').nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropColumn('player1_sets_won');
    table.dropColumn('player2_sets_won');
    table.dropColumn('set_scores');
  });
}
