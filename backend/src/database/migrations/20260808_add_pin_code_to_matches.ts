import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.string('pin_code', 6).nullable();
    table.index(['pin_code']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropIndex(['pin_code']);
    table.dropColumn('pin_code');
  });
}
