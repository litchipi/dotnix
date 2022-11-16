{ config, lib, pkgs, ... }:
# TODO  Cleanup code
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  cfg = config.cmn.software.moc;

  cfg_from_value = name: val: escape: if builtins.isBool val
      then if val then "yes" else "no"
    else if builtins.isList val
      then (builtins.concatStringsSep ":" val)
    else if builtins.isString val
      then
        if (builtins.stringLength val) == 0
        then ""
        else if escape then "\"${val}\"" else "${val}"
    else if builtins.isAttrs val
      then pkgs.writeText "moc_${name}" (write_config val false)
    else if builtins.isInt val
      then builtins.toString val
    else builtins.throw "Unknown type of MOC config ${name}, got '${builtins.toString val}'";

  write_config = conf: escape: let
  in (builtins.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (option: value: let
      line = "${option} = ${cfg_from_value option value escape}";
    in if builtins.isString value
      then if (builtins.stringLength value) == 0
        then ""
        else line
      else line
    ) conf
  )) + "\n\n";

  default_theme = {
    background = "white black";
    frame = "yellow black";
    window_title = "white black";
    directory = "white black bold";
    selected_directory = "black yellow";
    playlist = "white black";
    selected_playlist = "black yellow";
    file = "white black";
    selected_file = "black yellow";
    marked_file = "yellow black";
    marked_selected_file = "yellow black bold,reverse";
    info = "yellow black";
    selected_info = "yellow black bold";
    marked_info = "yellow black bold";
    marked_selected_info = "yellow black bold,reverse";
    status = "white black";
    title = "yellow black";
    state = "yellow black";
    current_time = "white black bold";
    time_left = "white black bold";
    total_time = "white black bold";
    time_total_frames = "white black";
    sound_parameters = "white black bold";
    legend = "white black";
    disabled = "black black bold";
    enabled = "white black bold";
    empty_mixer_bar = "white black";
    filled_mixer_bar = "black yellow";
    empty_time_bar = "white black";
    filled_time_bar = "white yellow";
    entry = "white black";
    entry_title = "yellow black bold";
    error = "yellow black bold";
    message = "yellow black bold";
    plist_time = "white black";
  };

  default_keymap = {
    quit_client = "q";
    quit = "Q";
    go = "ENTER";
    menu_down = "DOWN";
    menu_up = "UP";
    menu_page_down = "PAGE_DOWN";
    menu_page_up = "PAGE_UP";
    menu_first_item = "HOME";
    menu_last_item = "END";
    search_menu = "g /";
    toggle_read_tags = "f";
    toggle_show_time = "^t";
    toggle_show_format = "^f";
    toggle_menu = "TAB";
    toggle_layout = "l";
    toggle_hidden_files = "H";
    next_search = "^g ^n";
    show_lyrics = "L";
    theme_menu = "T";
    help = "h ?";
    refresh = "^r";
    reload = "r";
    seek_forward = "RIGHT";
    seek_backward = "LEFT";
    seek_forward_fast = "]";
    seek_backward_fast = "[";
    pause = "p SPACE";
    stop = "s";
    next = "n";
    previous = "b";
    toggle_shuffle = "S";
    toggle_repeat = "R";
    toggle_auto_next = "X";
    toggle_mixer = "x";
    go_url = "o";
    volume_down_1 = "<";
    volume_up_1 = ">";
    volume_down_5 = ",";
    volume_up_5 = ".";
    volume_10 = "M-1";
    volume_20 = "M-2";
    volume_30 = "M-3";
    volume_40 = "M-4";
    volume_50 = "M-5";
    volume_60 = "M-6";
    volume_70 = "M-7";
    volume_80 = "M-8";
    volume_90 = "M-9";
    go_to_a_directory = "i";
    go_to_music_directory = "m";
    go_to_fast_dir1 = "!";
    go_to_fast_dir2 = "@";
    go_to_fast_dir3 = "#";
    go_to_fast_dir4 = "$";
    go_to_fast_dir5 = "%";
    go_to_fast_dir6 = "^";
    go_to_fast_dir7 = "&";
    go_to_fast_dir8 = "*";
    go_to_fast_dir9 = "(";
    go_to_fast_dir10 = ")";
    go_to_playing_file = "G";
    go_up = "U";
    add_file = "a";
    add_directory = "A";
    plist_add_stream = "^u";
    delete_from_playlist = "d";
    playlist_full_paths = "P";
    plist_move_up = "u";
    plist_move_down = "j";
    save_playlist = "V";
    remove_dead_entries = "Y";
    clear_playlist = "C";
    enqueue_file = "z";
    clear_queue = "Z";
    history_up = "UP";
    history_down = "DOWN";
    delete_to_start = "^u";
    delete_to_end = "^k";
    cancel = "^x ESCAPE";
    hide_message = "M";
    toggle_softmixer = "w";
    toggle_make_mono = "J";
    toggle_equalizer = "E";
    equalizer_refresh = "e";
    equalizer_prev = "K";
    equalizer_next = "k";
    mark_start = "'";
    mark_end = "\"";
    exec_command1 = "F1";
    exec_command2 = "F2";
    exec_command3 = "F3";
    exec_command4 = "F4";
    exec_command5 = "F5";
    exec_command6 = "F6";
    exec_command7 = "F7";
    exec_command8 = "F8";
    exec_command9 = "F9";
    exec_command10 = "F10";
    toggle_percent = "M-P";
  };

  default_config = {
    Theme = if builtins.isNull cfg.theme_file then default_theme else "${cfg.theme_file}";
    Keymap = if builtins.isNull cfg.keymap_file then default_keymap else "${cfg.keymap_file}";
    HTTPProxy = "";
    ReadTags = true;
    MusicDir = config.base.home_cfg.xdg.userDirs.music;
    StartInMusicDir = true;
    ShowStreamErrors = false;
    MP3IgnoreCRCErrors = true;
    Repeat = false;
    Shuffle = false;
    AutoNext = true;
    FormatString = "%(n:%n :)%(a:%a - :)%(t:%t:)%(A: \\(%A\\):)";
    InputBuffer = 512;
    OutputBuffer = 512;
    Prebuffering = 64;
    SoundDriver = ["JACK" "ALSA" "OSS"];
    JackClientName = "moc";
    JackStartServer = false;
    JackOutLeft = ["system" "playback_1"];
    JackOutRight = ["system" "playback_2"];
    OSSDevice = "/dev/dsp";
    OSSMixerDevice = "/dev/mixer";
    OSSMixerChannel1 = "pcm";
    OSSMixerChannel2 = "master";
    ALSADevice = "default";
    ALSAMixer1 = "PCM";
    ALSAMixer2 = "Master";
    ALSAStutterDefeat = false;
    Softmixer_SaveState = true;
    Equalizer_SaveState = true;
    ShowHiddenFiles = false;
    HideFileExtension = false;
    ShowFormat = true;
    ShowTime = "IfAvailable";
    ShowTimePercent = false;
    ScreenTerms = [ "screen" "screen-w" "vt100"];
    XTerms = [
      "xterm"
      "xterm-colour"
      "xterm-color"
      "xterm-256colour"
      "xterm-256color"
      "rxvt"
      "rxvt-unicode"
      "rxvt-unicode-256colour"
      "rxvt-unicode-256color"
      "eterm"
    ];
    AutoLoadLyrics = false;
    MOCDir = "~/.moc";
    UseMMap = false;
    UseMimeMagic = false;
    ID3v1TagsEncoding = "WINDOWS-1250";
    UseRCC = true;
    UseRCCForFilesystem = true;
    EnforceTagsEncoding = false;
    FileNamesIconv = false;
    NonUTFXterm = false;
    Precache = true;
    SavePlaylist = true;
    SyncPlaylist = true;
    ASCIILines = false;
    Fastdir1 = "";
    Fastdir2 = "";
    Fastdir3 = "";
    Fastdir4 = "";
    Fastdir5 = "";
    Fastdir6 = "";
    Fastdir7 = "";
    Fastdir8 = "";
    Fastdir9 = "";
    Fastdir10 = "";
    SeekTime = 1;
    SilentSeekTime = 5;
    PreferredDecoders = [
      "aac(aac,ffmpeg)"
      "aac(aac,ffmpeg)" "m4a(ffmpeg)"
      "mpc(musepack,*,ffmpeg)" "mpc8(musepack,*,ffmpeg)"
      "sid(sidplay2)" "mus(sidplay2)"
      "wav(sndfile,*,ffmpeg)"
      "wv(wavpack,*,ffmpeg)"
      "audio/aac(aac)" "audio/aacp(aac)" "audio/m4a(ffmpeg)"
      "audio/wav(sndfile,*)"
      "ogg(vorbis,ffmpeg)" "oga(vorbis,ffmpeg)" "ogv(ffmpeg)"
      "opus(ffmpeg)"
      "spx(speex)"
      "application/ogg(vorbis)" "audio/ogg(vorbis)"
    ];
    ResampleMethod = "Linear";
    ForceSampleRate = 0;
    Allow24bitOutput = false;
    UseRealtimePriority = false;
    TagsCacheSize = 256;
    PlaylistNumbering = false;
    Layout1 = [ "directory(0,0,50%,100%)" "playlist(50%,0,FILL,100%)" ];
    Layout2 = [ "directory(0,0,100%,100%)" "playlist(0,0,100%,100%)" ];
    Layout3 = [];
    FollowPlayedFile = true;
    CanStartInPlaylist = true;
    ExecCommand1 = "";
    ExecCommand2 = "";
    ExecCommand3 = "";
    ExecCommand4 = "";
    ExecCommand5 = "";
    ExecCommand6 = "";
    ExecCommand7 = "";
    ExecCommand8 = "";
    ExecCommand9 = "";
    ExecCommand10 = "";
    UseCursorSelection = false;
    SetXtermTitle = true;
    SetScreenTitle = true;
    PlaylistFullPaths = false;
    BlockDecorators = "`\\\"'";
    MessageLingerTime = 3;
    PrefixQueuedMessages = true;
    ErrorMessagesQueued = "!";
    ModPlug_Oversampling = true;
    ModPlug_NoiseReduction = true;
    ModPlug_Reverb = false;
    ModPlug_MegaBass = false;
    ModPlug_Surround = false;
    ModPlug_ResamplingMode = "FIR";
    ModPlug_Channels = 2;
    ModPlug_Bits = 16;
    ModPlug_Frequency = 44100;
    ModPlug_ReverbDepth = 0;
    ModPlug_ReverbDelay = 0;
    ModPlug_BassAmount = 0;
    ModPlug_BassRange = 10;
    ModPlug_SurroundDepth = 0;
    ModPlug_SurroundDelay = 0;
    ModPlug_LoopCount = 0;
    TiMidity_Rate = 44100;
    TiMidity_Bits = 16;
    TiMidity_Channels = 2;
    TiMidity_Volume = 100;
    TiMidity_Config = "";
    SidPlay2_DefaultSongLength = 180;
    SidPlay2_MinimumSongLength = 0;
    SidPlay2_Frequency = 44100;
    SidPlay2_Bits = 16;
    SidPlay2_Optimisation = 0;
    SidPlay2_Database = "";
    SidPlay2_PlayMode = "M";
    SidPlay2_StartAtStart = true;
    SidPlay2_PlaySubTunes = true;
    OnSongChange = "";
    RepeatSongChange = false;
    OnStop = "";
    QueueNextSongReturn = true;
  };

  options_from_default_config = builtins.mapAttrs (name: val: lib.mkOption {
    type = with lib.types;
      if builtins.isBool val then bool
      else if builtins.isList val then listOf str
      else if builtins.isInt val then int
      else if builtins.isString val then str
      else if builtins.isPath val then path
      else if builtins.isAttrs val then attrs
      else anything;
    description = "MOC ${name} option";
    default = val;
  }) default_config;
in
libconf.create_common_confs [
  {
    name = "moc";
    parents = [ "software" ];
    add_pkgs = [ pkgs.moc ];
    add_opts = {
      manual_config = options_from_default_config;
      theme_file = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "Theme file to use instead of configuration-generated one";
      };
      keymap_file = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "Keymap file to use instead of configuration-generated one";
      };
    };
    home_cfg.home.file = {
      ".config/moc/config".text = write_config cfg.manual_config true;
    };
  }
]
