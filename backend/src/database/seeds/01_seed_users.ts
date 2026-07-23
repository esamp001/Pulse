import type { Knex } from 'knex';
import bcrypt from 'bcrypt';

export async function seed(knex: Knex): Promise<void> {
  // Deletes ALL existing entries
  await knex('users').del();

  const defaultPassword = await bcrypt.hash('password123', 10);

  // Inserts seed entries
  await knex('users').insert([
    {
      name: 'John Doe',
      email: 'john@example.com',
      password_hash: defaultPassword,
      rating: 1200,
      wins: 5,
      losses: 2,
    },
    {
      name: 'Jane Smith',
      email: 'jane@example.com',
      password_hash: defaultPassword,
      rating: 1350,
      wins: 10,
      losses: 3,
    },
  ]);
}
