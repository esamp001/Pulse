import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('courts', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('osm_id', 64).nullable();
    table.string('name', 255).notNullable();
    table.text('address').nullable();
    table.string('city', 128).nullable();
    table.double('latitude').notNullable();
    table.double('longitude').notNullable();
    table.jsonb('sports').notNullable().defaultTo('[]');
    table.string('surface', 64).nullable();
    table.boolean('has_lighting').notNullable().defaultTo(false);
    table.boolean('is_indoor').notNullable().defaultTo(false);
    table.string('access_type', 64).notNullable().defaultTo('public');
    table.boolean('is_verified').notNullable().defaultTo(true);
    table.uuid('created_by').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.timestamps(true, true);

    // Mandatory indexes per project rules
    table.index(['latitude', 'longitude']);
    table.index(['osm_id']);
    table.index(['city']);
    table.index(['is_verified']);
    table.index(['created_by']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('courts');
}
