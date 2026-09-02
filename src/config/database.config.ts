import configuration from './configuration';
export const databaseConfig = (): ReturnType<typeof configuration>['database'] => configuration().database;
