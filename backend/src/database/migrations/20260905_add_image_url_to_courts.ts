import type { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  const hasColumn = await knex.schema.hasColumn('courts', 'image_url');
  if (!hasColumn) {
    await knex.schema.alterTable('courts', (table) => {
      table.text('image_url').nullable();
    });
  }
}

export async function down(knex: Knex): Promise<void> {
  const hasColumn = await knex.schema.hasColumn('courts', 'image_url');
  if (hasColumn) {
    await knex.schema.alterTable('courts', (table) => {
      table.dropColumn('image_url');
    });
  }
}
