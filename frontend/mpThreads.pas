unit mpThreads;

interface

uses
  Classes, SysUtils, shlObj, Dialogs,
  // mte units
  mteHelpers, mteLogger, mteTracker,
  // mp units
  mpMerge, mpFrontend,
  // xedit units
  wbBSA, wbInterface, wbImplementation;


type
  // THREADS AND CALLBACKS
  TCallback = procedure of object;
  TStatusCallback = procedure(s: string) of object;
  TInitThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TConnectThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TLoaderThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TErrorCheckThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TErrorFixThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TMergeThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TSaveThread = class(TThread)
  protected
    procedure Execute; override;
  end;

var
  InitCallback, LoaderCallback, ErrorCheckCallback, ErrorFixCallback,
  MergeCallback, SaveCallback, UpdateCallback, ConnectCallback: TCallback;
  StatusCallback: TStatusCallback;

implementation


{******************************************************************************}
{ THREAD METHODS
  These are threads that the program will run for various large jobs which need
  to be decoupled from general program operation and the GUI.

  List of methods:
  - TInitThread.Execute
  - LoaderProgress
  - TLoaderThread.Execute
  - TErrorCheckThread.Execute
  - TMergeThread.Execute
  - TSaveThread.Execute
}
{******************************************************************************}

{ TConnectThread }
procedure TConnectThread.Execute;
begin
  ConnectToServer;
  if Assigned(ConnectCallback) then
    Synchronize(nil, ConnectCallback);
end;

{ TInitThread }
procedure TInitThread.Execute;
var
  wbPluginsFileName: string;
  sl: TStringList;
  i: integer;
  plugin: TPlugin;
  aFile: IwbFile;
begin
  try
    // INITIALIZE VARIABLES
    ProgramVersion := GetVersionMem;
    TempPath := ProgramPath + 'temp\';
    LogPath := ProgramPath + 'logs\';
    ProfilePath := ProgramPath + 'profiles\' + CurrentProfile.name + '\';
    ForceDirectories(TempPath);
    ForceDirectories(LogPath);
    ForceDirectories(ProfilePath);
    MergesList := TList.Create;
    PluginsList := TList.Create;
    bLoaderDone := false;
    LastStatusTime := 0;
    Status := TmpStatus.Create;
    LoadChangelog;

    // SET GAME VARS
    SetGame(CurrentProfile.gameMode);
    wbVWDInTemporary := wbGameMode in [gmTES5, gmFO3, gmFNV];
    Logger.Write('GENERAL', 'Game', 'Using '+wbGameName);
    Logger.Write('GENERAL', 'Path', 'Using '+wbDataPath);

    // INITIALIZE SETTINGS FOR GAME
    LoadSettings;
    LoadLanguage;
    if settings.usingMO then
      ModOrganizerInit;

    // INITIALIZE TES5EDIT API
    wbDisplayLoadOrderFormID := True;
    wbSortSubRecords := True;
    wbDisplayShorterNames := True;
    wbHideUnused := True;
    wbFlagsAsArray := True;
    wbRequireLoadOrder := True;
    wbLanguage := settings.language;
    wbEditAllowed := True;
    handler := wbCreateContainerHandler;
    handler._AddRef;

    // IF AUTOMATIC UPDATING IS ENABLED, CHECK FOR UPDATE
    InitializeClient;
    if settings.updateDictionary or settings.updateProgram then try
      Tracker.Write('Checking for updates');
      ConnectToServer;
      if TCPClient.Connected then begin
        UpdateCallback;
        if bInstallUpdate then begin
          InitCallback;
          exit;
        end;
      end;
    except
      on x: Exception do
        Logger.Write('CLIENT', 'Update', 'Failed to get automatic update '+x.Message);
    end;

    // INITIALIZE DICTIONARY
    dictionaryFilename := wbAppName+'Dictionary.txt';
    Logger.Write('GENERAL', 'Dictionary', 'Using '+dictionaryFilename);
    LoadDictionary;

    // INITIALIZE TES5EDIT DEFINITIONS
    Logger.Write('GENERAL', 'Definitions', 'Using '+wbAppName+'Edit Definitions');
    LoadDefinitions;

    // LOAD MERGES
    Tracker.Write('Loading merges');
    LoadMerges;

    // PREPARE TO LOAD PLUGINS
    if settings.usingMO then
      wbPluginsFileName := settings.MOPath + 'profiles\'+ActiveModProfile+'\plugins.txt'
    else
      wbPluginsFileName := GetCSIDLShellFolder(CSIDL_LOCAL_APPDATA) + wbGameName + '\Plugins.txt';
    Logger.Write('GENERAL', 'Load Order', 'Using '+wbPluginsFileName);
    sl := TStringList.Create;
    sl.LoadFromFile(wbPluginsFileName);
    RemoveCommentsAndEmpty(sl);
    RemoveMissingFiles(sl);
    RemoveMergedPlugins(sl);
    // if GameMode is not Skyrim sort by date modified
    // else add Update.esm and Skyrim.esm to load order
    if wbGameMode <> gmTES5 then begin
      GetPluginDates(sl);
      sl.CustomSort(PluginListCompare);
    end
    else begin
      if sl.IndexOf('Update.esm') = -1 then
        sl.Insert(0, 'Update.esm');
      if sl.IndexOf('Skyrim.esm') = -1 then
        sl.Insert(0, 'Skyrim.esm');
    end;

    // PRINT LOAD ORDER TO LOG
    for i := 0 to Pred(sl.Count) do
      Logger.Write('LOAD', 'Order', '['+IntToHex(i, 2)+'] '+sl[i]);

    // LOAD PLUGINS
    for i := 0 to Pred(sl.Count) do begin
      Tracker.Write('Loading '+sl[i]);
      try
        plugin := TPlugin.Create;
        plugin.filename := sl[i];
        plugin._File := wbFile(wbDataPath + sl[i], i);
        plugin._File._AddRef;
        plugin.GetData;
        PluginsList.Add(Pointer(plugin));
      except
        on x: Exception do begin
          Logger.Write('ERROR', 'Load', 'Exception loading '+sl[i]+', '+x.Message);
          bDontSave := true;
        end;
      end;

      // load hardcoded dat
      if i = 0 then try
        aFile := wbFile(wbProgramPath + wbGameName + wbHardcodedDat, 0);
        aFile._AddRef;
      except
        on x: Exception do begin
          Logger.Write('ERROR', 'Load', 'Exception loading '+wbGameName+wbHardcodedDat+
           ', please download and install this dat file!');
          raise x;
        end;
      end;
    end;

    // LOAD PLUGIN INFORMATION
    Tracker.Write('Loading plugin information');
    AssignMergesToPlugins;
    LoadPluginInfo;

    // CLEAN UP
    sl.Free;
  except
    on x: Exception do begin
      if Assigned(sl) then
        sl.Free;
      bDontSave := true;
      Logger.Write('ERROR', 'Load', x.Message);
    end;
  end;

  if Assigned(InitCallback) then
    Synchronize(nil, InitCallback);
end;

{ TLoaderThread }
procedure LoaderProgress(const s: string);
begin
  if s <> '' then
    Logger.Write('LOAD', 'Background', s);
  if bForceTerminate then
    Abort;
end;

procedure TLoaderThread.Execute;
var
  i: Integer;
  f: IwbFile;
  plugin: TPlugin;
begin
  StatusCallback(Format('%s (%d/%d)',
    [GetString('mpMain_LoaderInProgress'), 1, PluginsList.Count]));
  try
    for i := 0 to Pred(PluginsList.Count) do begin
      StatusCallback(Format('%s (%d/%d)',
        [GetString('mpMain_LoaderInProgress'), i + 1, PluginsList.Count]));
      plugin := TPlugin(PluginsList[i]);
      f := plugin._File;
      if SameText(plugin.filename, wbGameName + '.esm') then
        continue;
      LoaderProgress('[' + plugin.filename + '] Building reference info.');
      f.BuildRef;
      if bForceTerminate then begin
        LoaderProgress('Aborted.');
        break;
      end;
    end;
  except
    on E: Exception do begin
      LoaderProgress('Fatal: <' + e.ClassName + ': ' + e.Message + '>');
      wbLoaderError := true;
      bDontSave := true;
    end;
  end;
  bLoaderDone := true;
  LoaderProgress('finished');
  StatusCallback(GetString('mpMain_LoaderFinished'));
  if Assigned(LoaderCallback) then
    Synchronize(nil, LoaderCallback);
end;

{ TErrorCheckThread }
procedure TErrorCheckThread.Execute;
var
  i: integer;
  plugin: TPlugin;
begin
  // check merges for errors
  for i := 0 to Pred(pluginsToHandle.Count) do begin
    if Tracker.Cancel then break;
    plugin := TPlugin(pluginsToHandle[i]);
    StatusCallback(Format('%s "%s" (%d/%d)',
      [GetString('mpProg_Checking'), plugin.filename, i + 1, pluginsToHandle.Count]));
    // check plugins for errors
    Tracker.Write('Checking for errors in '+plugin.filename);
    plugin.FindErrors;
    Tracker.SetProgress(IntegerListSum(timeCosts, i));
    if Tracker.Cancel then Tracker.Write('Check for errors canceled.');
  end;
  // inform user thread is done if it wasn't cancelled
  if not Tracker.Cancel then
    Tracker.Write('All done!');

  Tracker.Cancel := false;
  StatusCallback(GetString('mpProg_DoneChecking'));
  if Assigned(ErrorCheckCallback) then
    Synchronize(nil, ErrorCheckCallback);
end;

{ TErrorFixThread }
procedure TErrorFixThread.Execute;
var
  i: integer;
  plugin: TPlugin;
begin
  // check merges for errors
  for i := 0 to Pred(pluginsToHandle.Count) do begin
    if Tracker.Cancel then break;
    plugin := TPlugin(pluginsToHandle[i]);
    StatusCallback(Format('%s "%s" (%d/%d)',
      [GetString('mpProg_Fixing'), plugin.filename, i + 1, pluginsToHandle.Count]));
    // check plugins for errors
    Tracker.Write('Fixing errors in '+plugin.filename);
    plugin.ResolveErrors;
    Tracker.SetProgress(IntegerListSum(timeCosts, i));
    if Tracker.Cancel then Tracker.Write('Fix errors canceled.');
  end;
  // inform user thread is done if it wasn't cancelled
  if not Tracker.Cancel then
    Tracker.Write('All done!');

  Tracker.Cancel := false;
  StatusCallback(GetString('mpProg_DoneFixing'));
  if Assigned(ErrorFixCallback) then
    Synchronize(nil, ErrorFixCallback);
end;

{ TMergeThread }
procedure TMergeThread.Execute;
var
  i, j: integer;
  merge: TMerge;
  slGeck, slNav: TStringList;
begin
  // build merges
  for i := 0 to Pred(mergesToBuild.Count) do begin
    if Tracker.Cancel then break;
    merge := TMerge(mergesToBuild[i]);
    StatusCallback(Format('%s "%s" (%d/%d)',
      [GetString('mpProg_Merging'), merge.name, i + 1, mergesToBuild.Count]));
    try
      if (merge.status in RebuildStatuses) then
        RebuildMerge(merge)
      else
        BuildMerge(merge);
    except
      on x : Exception do begin
        merge.status := msFailed;
        Tracker.Write('Exception: '+x.Message);
      end;
    end;
    Tracker.Write(' '#13#10);
    Tracker.SetProgress(IntegerListSum(timeCosts, i));
    if Tracker.Cancel then Tracker.Write('Merging canceled.');
  end;

  // build list of post-merge steps
  slGeck := TStringList.Create;
  slNav := TStringList.Create;
  for i := 0 to Pred(mergesToBuild.Count) do begin
    merge := TMerge(mergesToBuild[i]);
    // build geck scripts list
    if merge.geckScripts.Count > 0 then begin
      slGeck.Add(Format('[%s]', [merge.filename]));
      for j := 0 to Pred(merge.geckScripts.Count) do
        slGeck.Add('  '+merge.geckScripts[j]);
      slGeck.Add(' ');
    end;
    // build nav list
    if merge.navConflicts.Count > 0 then begin
      slNav.Add(Format('[%s]', [merge.filename]));
      for j := 0 to Pred(merge.navConflicts.Count) do
        slNav.Add('  '+merge.navConflicts[j]);
      slNav.Add(' ');
    end;
  end;

  // inform user about post-merge steps
  if slGeck.Count > 0 then
    ShowMessage(Format(GetString('mpProg_GeckScripts'), [Trim(slGeck.Text)]));
  if slNav.Count > 0 then
    ShowMessage(Format(GetString('mpProg_NavConflicts'), [Trim(slNav.Text)]));

  // say thread is done if it wasn't cancelled
  if not Tracker.Cancel then
    Tracker.Write('All done!');

  // clean up, fire callback
  StatusCallback(GetString('mpProg_DoneBuilding'));
  Tracker.Cancel := false;
  if Assigned(MergeCallback) then
    Synchronize(nil, MergeCallback);
end;

{ TSaveThread }
procedure TSaveThread.Execute;
begin
  // send statistics, then disconnect from the server
  if not settings.dontSendStatistics then
    SendStatistics;
  TCPClient.Disconnect;

  // save ESPs only if it's safe to do so
  if not bDontSave then begin
    // Save plugin errors
    SavePluginInfo;
    Tracker.SetProgress(PluginsList.Count + 1);
    Tracker.Write(' ');
    // save merges
    SaveMerges;
    // rename saved plugins
    if bLoaderDone then RenameSavedPlugins;
  end;

  // save statistics and settings
  SaveStatistics;
  SaveSettings;

  // delete temppath
  if not settings.preserveTempPath then
    DeleteTempPath;

  Tracker.Cancel := false;
  if Assigned(SaveCallback) then
    Synchronize(nil, SaveCallback);
end;


end.
