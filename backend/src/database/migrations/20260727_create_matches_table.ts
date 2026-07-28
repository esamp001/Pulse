import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('matches', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('creator_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('player1_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('player2_id').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.uuid('scorer_id').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.enum('sport', ['pickleball', 'tennis', 'table_tennis']).notNullable();
    table.string('venue_name').notNullable();
    table.string('location').nullable();
    table.timestamp('scheduled_at', { useTz: true }).notNullable();
    table.enum('status', ['WAITING', 'READY', 'LIVE', 'FINISHED', 'CONFIRMED']).notNullable().defaultTo('WAITING');
    table.uuid('winner_id').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('matches');
}
