unit mtePluginSelectionForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CommCtrl, Menus, ComCtrls, ImgList;

type
  TPluginListItem = class(TObject)
  public
    StateIndex: Integer;
    Fields: TStringList;
    constructor Create; virtual;
    destructor Destroy; override;
  end;
  TStringFunction = function(s: string): string of object;
  TStringListProcedure = procedure(fn: string; var sl: TStringList) of object;
  TPluginSelectionForm = class(TForm)
    lvPlugins: TListView;
    btnCancel: TButton;
    btnOK: TButton;
    PluginsPopupMenu: TPopupMenu;
    CheckAllItem: TMenuItem;
    UncheckAllItem: TMenuItem;
    ToggleAllItem: TMenuItem;
    StateImages: TImageList;
    procedure LoadFields(aListItem: TPluginListItem; sPlugin: string);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure CheckAllItemClick(Sender: TObject);
    procedure UncheckAllItemClick(Sender: TObject);
    procedure ToggleAllItemClick(Sender: TObject);
    procedure lvPluginsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lvPluginsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lvPluginsChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    function GetMasterStatus(filename: string): Integer;
    procedure lvPluginsData(Sender: TObject; Item: TListItem);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DrawCheckbox(aCanvas: TCanvas; var x, y: Integer; state: Integer);
    procedure DrawSubItems(ListView: TListView; var R: TRect; Item: TListItem);
    procedure DrawItem(ListView: TListView; var R: TRect; Item: TListItem);
    procedure lvPluginsDrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
    procedure lvPluginsMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
    slMasters, slDependencies: TStringList;
    ListItems: TList;
    LastHint: string;
  public
    { Public declarations }
    GetPluginInfo: TStringFunction;
    GetPluginMasters: TStringListProcedure;
    GetPluginDependencies: TStringListProcedure;
    sColumns: string;
    slAllPlugins, slCheckedPlugins: TStringList;
  end;

var
  PluginSelectionForm: TPluginSelectionForm;

implementation

uses
  mteHelpers;

const
  cChecked = 1;
  cUnChecked = 2;
  msNone = 0;
  msMaster = 1;
  msDependency = 2;
  msBoth = 3;

{$R *.dfm}

constructor TPluginListItem.Create;
begin
  StateIndex := cUnChecked;
  Fields := TStringList.Create;
end;

destructor TPluginListItem.Destroy;
begin
  Fields.Free;
end;

procedure TPluginSelectionForm.btnOKClick(Sender: TObject);
var
  i: Integer;
  ListItem: TListItem;
begin
  // clear checked plugins list
  slCheckedPlugins.Clear;
  // add checked plugins to slCheckedPlugins
  for i := 0 to Pred(lvPlugins.Items.Count) do begin
    ListItem := lvPlugins.Items[i];
    if ListItem.StateIndex = cChecked then
      slCheckedPlugins.Add(ListItem.Caption);
  end;
end;

procedure TPluginSelectionForm.LoadFields(aListItem: TPluginListItem;
  sPlugin: string);
var
  sl: TStringList;
  i: Integer;
begin
  // add plugin filename
  aListItem.fields.Add(sPlugin);

  // get comma separated plugin info in a TStringList
  sl := TStringList.Create;
  try
    sl.CommaText := GetPluginInfo(sPlugin);
    for i := 0 to Pred(sl.Count) do
      aListItem.Fields.Add(sl[i]);
  finally
    sl.Free;
  end;
end;

procedure ToggleState(ListItem: TPluginListItem);
begin
  case ListItem.StateIndex of
    cChecked: ListItem.StateIndex := cUnChecked;
    cUnChecked: ListItem.StateIndex := cChecked;
  end;
end;

procedure TPluginSelectionForm.lvPluginsChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  i: Integer;
  filename: string;
begin
  // update slMasters and slDependencies
  slMasters.Clear;
  slDependencies.Clear;
  for i := 0 to Pred(lvPlugins.Items.Count) do begin
    filename := TPluginListItem(ListItems[i]).Fields[0];
    with lvPlugins.Items[i] do
      if Selected then begin
        GetPluginMasters(filename, slMasters);
        GetPluginDependencies(filename, slDependencies);
      end;
  end;

  // repaint to update master/dependency colors
  lvPlugins.Repaint;
end;

function TPluginSelectionForm.GetMasterStatus(filename: string): Integer;
var
  bIsDependency, bIsMaster: boolean;
begin
  bIsMaster := slMasters.IndexOf(filename) > -1;
  bIsDependency := slDependencies.IndexOf(filename) > -1;
  Result := IfThenInt(bIsMaster, 1, 0) + IfThenInt(bIsDependency, 2, 0);
end;

procedure TPluginSelectionForm.lvPluginsData(Sender: TObject; Item: TListItem);
var
  aListItem: TPluginListItem;
  MasterStatus: Integer;
  i: Integer;
begin
  // get item data
  aListItem := ListItems[Item.Index];
  Item.Caption := aListItem.Fields[0];
  Item.StateIndex := aListItem.StateIndex;
  // get subitems
  for i := 1 to Pred(aListItem.fields.Count) do
    Item.SubItems.Add(aListItem.fields[i]);

  // set font color based on master status of item
  lvPlugins.Canvas.Font.Style := [fsBold];
  MasterStatus := GetMasterStatus(Item.Caption);
  case MasterStatus of
    msNone: begin
      lvPlugins.Canvas.Font.Style := [];
      lvPlugins.Canvas.Font.Color := clBlack;
    end;
    msMaster: lvPlugins.Canvas.Font.Color := clGreen;
    msDependency: lvPlugins.Canvas.Font.Color := clMaroon;
    msBoth: lvPlugins.Canvas.Font.Color := clPurple;
  end;
end;

procedure TPluginSelectionForm.DrawCheckbox(aCanvas: TCanvas; var x, y: Integer;
  state: Integer);
var
  icon: TIcon;
begin
  if state = 0 then
    exit;
  icon := TIcon.Create;
  StateImages.GetIcon(state, icon);
  aCanvas.Draw(x, y, icon);
  Inc(x, 17);
  icon.Free;
end;

procedure TPluginSelectionForm.DrawSubItems(ListView: TListView; var R: TRect;
  Item: TListItem);
var
  i: Integer;
begin
  for i := 0 to Pred(Item.SubItems.Count) do begin
    // redefine rect to draw in the space for the column
    // use trailing padding to keep items lined up on columns
    R.Left := R.Right;
    R.Right := R.Left + ListView_GetColumnWidth(ListView.Handle, i) - 3;

    // padding between items
    Inc(R.Left, 3);

    // draw text
    ListView.Canvas.TextRect(R, R.Left, R.Top, Item.SubItems[i]);
  end;
end;

procedure TPluginSelectionForm.DrawItem(ListView: TListView; var R: TRect;
  Item: TListItem);
begin
  // redefine rect to draw until the end of the first column
  // use trailing padding to keep items lined up on columns
  R.Right := R.Left + ListView.Columns[0].Width - 3;

  // draw the checkbox
  DrawCheckbox(ListView.Canvas, R.Left, R.Top, Item.StateIndex);

  // move text down 1 pixel
  Inc(R.Top, 1);
  // padding between checkbox and text
  Inc(R.Left, 6);

  // draw text
  ListView.Canvas.TextRect(R, R.Left, R.Top, Item.Caption);
end;

procedure TPluginSelectionForm.lvPluginsDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  ListView: TListView;
begin
  // draw background color
  ListView := TListView(Sender);
  if Item.Selected then begin
    ListView.Canvas.Brush.Color := $FFEEDD;
    ListView.Canvas.FillRect(Rect);
  end;

  // draw item
  DrawItem(ListView, Rect, Item);
  // draw subitem
  DrawSubItems(ListView, Rect, Item);
end;


procedure TPluginSelectionForm.lvPluginsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
  ListItem: TListItem;
begin
  // allow user to use space to toggle checkbox state
  // for all selected items
  if Key = VK_SPACE then begin
    for i := 0 to Pred(lvPlugins.Items.Count) do begin
      ListItem := lvPlugins.Items[i];
      if ListItem.Selected then
        ToggleState(TPluginListItem(ListItems[i]));
    end;
  end;

  // repaint to show updated checkbox state
  lvPlugins.Repaint;
end;

function OnStateIcon(X, Y: Integer): Boolean;
begin
  Result := (x >= 2) and (x <= 14);
end;

procedure TPluginSelectionForm.lvPluginsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ListItem: TListItem;
begin
  // toggle checkbox state
  ListItem := lvPlugins.GetItemAt(X, Y);
  if OnStateIcon(X, Y) then
    ToggleState(TPluginListItem(ListItems[ListItem.Index]));

  // repaint to show updated checkbox state
  lvPlugins.Repaint;
end;

procedure TPluginSelectionForm.lvPluginsMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
  li : TListItem;
  hint: string;
  slTempMasters, slTempReq: TStringList;
begin
  // get list item at mouse position
  pt := lvPlugins.ScreenToClient(Mouse.CursorPos);
  li := lvPlugins.GetItemAt(pt.x, pt.y);
  // if mouse not over an item, exit
  if not Assigned(li) then
    exit;

  // get plugin masters and display them if they're present
  slTempMasters := TStringList.Create;
  try
    GetPluginMasters(li.Caption, slTempMasters);
    if slTempMasters.Count > 0 then
      hint := Format('Masters:'#13#10'%s'#13#10, [slTempMasters.Text]);
  finally
    slTempMasters.Free;
  end;

  // get plugin dependencies and display them if they're present
  slTempReq := TStringList.Create;
  try
    GetPluginDependencies(li.Caption, slTempReq);
    if slTempReq.Count > 0 then
      hint := hint + Format('Required By:'#13#10'%s', [slTempReq.Text]);
  finally
    slTempReq.Free;
  end;

  // trim the hint
  hint := Trim(hint);

  // activate hint if it differs from previously displayed hint
  if (hint <> LastHint) then begin
    LastHint := hint;
    lvPlugins.Hint := hint;
    Application.ActivateHint(Mouse.CursorPos);
  end;
end;

procedure TPluginSelectionForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  slMasters.Free;
  slDependencies.Free;
  ListItems.Free;
end;

procedure TPluginSelectionForm.FormShow(Sender: TObject);
var
  i, iColumnSize: Integer;
  aListItem: TPluginListItem;
  sPlugin: string;
  sl: TStringList;
  aColumn: TListColumn;
begin
  // create lists
  slMasters := TStringList.Create;
  slDependencies := TStringList.Create;
  ListItems := TList.Create;

  // create columns
  sl := TStringList.Create;
  try
    sl.CommaText := sColumns;
    iColumnSize := (lvPlugins.ClientWidth - 310) div (sl.Count - 1);
    for i := 0 to Pred(sl.Count) do begin
      aColumn := lvPlugins.Columns.Add;
      aColumn.Caption := sl[i];
      aColumn.Width := IfThenInt(i = 0, 310, iColumnSize);
    end;
    // make first column autosize
    lvPlugins.Columns[0].AutoSize := true;
  finally
    sl.Free;
  end;

  // add plugin items to list
  for i := 0 to Pred(slAllPlugins.Count) do begin
    sPlugin := slAllPlugins[i];
    aListItem := TPluginListItem.Create;
    // check ListItem if it's in the CheckedPlugins list
    if slCheckedPlugins.IndexOf(sPlugin) > -1 then
      aListItem.StateIndex := cChecked;
    // add merge subitems
    LoadFields(aListItem, sPlugin);
    ListItems.Add(aListItem);
  end;

  // set plugin count for display
  lvPlugins.Items.Count := slAllPlugins.Count;
  CorrectListViewWidth(lvPlugins);
end;

procedure TPluginSelectionForm.CheckAllItemClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to Pred(lvPlugins.Items.Count) do
    TPluginListItem(ListItems[i]).StateIndex := cChecked;

  // repaint to show updated checkbox state
  lvPlugins.Repaint;
end;

procedure TPluginSelectionForm.UncheckAllItemClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to Pred(lvPlugins.Items.Count) do
    TPluginListItem(ListItems[i]).StateIndex := cUnChecked;

  // repaint to show updated checkbox state
  lvPlugins.Repaint;
end;

procedure TPluginSelectionForm.ToggleAllItemClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to Pred(lvPlugins.Items.Count) do
    ToggleState(TPluginListItem(ListItems[i]));

  // repaint to show updated checkbox state
  lvPlugins.Repaint;
end;

end.
