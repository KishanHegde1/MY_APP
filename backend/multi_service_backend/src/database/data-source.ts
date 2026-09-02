import 'reflect-metadata';
import 'dotenv/config';
import { DataSource, DataSourceOptions } from 'typeorm';
import configuration from '../config/configuration';
import { createTypeOrmOptions } from '../config/typeorm.config';

const config = configuration();
const migrationDatabaseUrl = config.database.directUrl ?? config.database.url;

export default new DataSource(createTypeOrmOptions(config, migrationDatabaseUrl) as DataSourceOptions);
