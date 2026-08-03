import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('notifications', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('category', 32).notNullable(); // ACCOUNT, INVITE, RATING, VERIFIED
    table.string('title', 255).notNullable();
    table.text('subtitle').notNullable();
    table.boolean('is_read').notNullable().defaultTo(false);
    table.jsonb('payload').nullable();
    table.timestamps(true, true);

    table.index(['user_id', 'is_read']);
    table.index(['user_id', 'created_at']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('notifications');
}
