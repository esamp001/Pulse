import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('community_waitlist', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').nullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('email', 255).notNullable();
    table.string('feature', 64).notNullable().defaultTo('community');
    table.timestamps(true, true);

    table.index(['user_id']);
    table.index(['email']);
    table.index(['feature']);
    table.unique(['user_id', 'feature']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('community_waitlist');
}
