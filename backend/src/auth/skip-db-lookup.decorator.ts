import { SetMetadata } from '@nestjs/common';

export const SKIP_DB_LOOKUP_KEY = 'skip_db_lookup';
export const SkipDbLookup = () => SetMetadata(SKIP_DB_LOOKUP_KEY, true);
