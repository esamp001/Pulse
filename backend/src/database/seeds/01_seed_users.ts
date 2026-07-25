import type { Knex } from 'knex';

export async function seed(knex: Knex): Promise<void> {
  // Deletes ALL existing user entries without creating default users
  await knex('users').del();
}
