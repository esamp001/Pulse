import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.string('phone_number').nullable();
    table.string('location').nullable();
    table.text('bio').nullable();

    table.index(['location']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.dropIndex(['location']);
    table.dropColumn('phone_number');
    table.dropColumn('location');
    table.dropColumn('bio');
  });
}
