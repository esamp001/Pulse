import type { Knex } from 'knex';

export async function seed(knex: Knex): Promise<void> {
  // Remove previously seeded placeholder courts so users add their own courts dynamically
  await knex('courts')
    .whereIn('id', [
      '11111111-1111-1111-1111-111111110001',
      '11111111-1111-1111-1111-111111110002',
      '11111111-1111-1111-1111-111111110003',
      '11111111-1111-1111-1111-111111110004',
      '11111111-1111-1111-1111-111111110005',
    ])
    .del();
}

