import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.integer('total_sets').notNullable().defaultTo(3);
    table.integer('points_to_win_set').notNullable().defaultTo(11);
    table.boolean('win_by_two').notNullable().defaultTo(true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropColumn('total_sets');
    table.dropColumn('points_to_win_set');
    table.dropColumn('win_by_two');
  });
}
