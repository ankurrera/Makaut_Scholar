-- =========================================
-- DROP YOUTUBE PLAYLISTS FEATURE
-- =========================================

-- 1. Drop the trigger that auto-syncs subjects_bundle
DROP TRIGGER IF EXISTS on_youtube_playlist_changes ON public.youtube_playlists;

-- 2. Drop the trigger function
DROP FUNCTION IF EXISTS public.sync_subjects_bundle_youtube();

-- 3. Drop the table itself (this automatically drops its RLS policies)
DROP TABLE IF EXISTS public.youtube_playlists;

-- Note: The subjects_bundle table will retain the subjects that were synced previously.
-- If you want to remove subjects that *only* had youtube playlists (and no notes/pyqs),
-- you'll have to manually clean those up or wait until the next `subjects_bundle` sync.
