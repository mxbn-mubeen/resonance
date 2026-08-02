/// Folders excluded from scanning by default (see "Folder Manager" in spec).
/// Users can toggle these in Settings; this is only the shipped default.
const List<String> kDefaultExcludedFolderNames = [
  'Telegram',
  'WhatsApp',
  'Recorder',
  'Notifications',
  'Podcasts',
];

/// Growing blacklist of filename tokens injected by piracy/download sites.
/// Used by [MetadataCleaner] to strip junk before generating a search query.
/// Users can extend this list from Settings ("custom rules").
const List<String> kWebsiteBlacklist = [
  'masstamilan',
  'isaimini',
  'pagalworld',
  'songspk',
  'djmaza',
  'kuttyweb',
  'tamilwire',
  'tamilblasters',
  'spotifydownloader',
  'spotiflyer',
  'ytmp3',
  'youtube downloader',
];

/// Tokens indicating quality/source noise rather than song metadata.
const List<String> kNoiseTokens = [
  'official',
  'official video',
  'official audio',
  'download',
  'full song',
  'lyrical',
  'lyric video',
  '128kbps',
  '192kbps',
  '320kbps',
  'hd',
  '4k',
];

const int kIsarSchemaVersion = 1;
