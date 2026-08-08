import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.uuid('creator_id').nullable().alter();
    table.uuid('player1_id').nullable().alter();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.uuid('creator_id').notNullable().alter();
    table.uuid('player1_id').notNullable().alter();
  });
}
