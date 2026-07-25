import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.boolean('is_onboarded').notNullable().defaultTo(false);
    table.string('primary_sport').notNullable().defaultTo('pickleball');
    table.string('avatar_url').nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('is_onboarded');
    table.dropColumn('primary_sport');
    table.dropColumn('avatar_url');
  });
}
