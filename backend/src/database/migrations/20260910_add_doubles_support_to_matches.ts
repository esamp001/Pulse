import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.string('match_type', 20).notNullable().defaultTo('singles');
    table.uuid('team1_partner_id').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.boolean('team1_partner_accepted').notNullable().defaultTo(false);
    table.uuid('team2_partner_id').nullable().references('id').inTable('users').onDelete('SET NULL');
    table.boolean('team2_partner_accepted').notNullable().defaultTo(false);

    // Mandatory table indexes
    table.index(['match_type']);
    table.index(['team1_partner_id']);
    table.index(['team2_partner_id']);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('matches', (table) => {
    table.dropIndex(['match_type']);
    table.dropIndex(['team1_partner_id']);
    table.dropIndex(['team2_partner_id']);

    table.dropColumn('match_type');
    table.dropColumn('team1_partner_id');
    table.dropColumn('team1_partner_accepted');
    table.dropColumn('team2_partner_id');
    table.dropColumn('team2_partner_accepted');
  });
}
