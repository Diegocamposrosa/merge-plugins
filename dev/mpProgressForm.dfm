object ProgressForm: TProgressForm
  Left = 0
  Top = 0
  Caption = 'Progress'
  ClientHeight = 315
  ClientWidth = 670
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    670
    315)
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressLabel: TLabel
    Left = 8
    Top = 8
    Width = 42
    Height = 13
    Caption = 'Progress'
  end
  object LogMemo: TMemo
    Left = 8
    Top = 58
    Width = 654
    Height = 249
    Anchors = [akLeft, akTop, akRight, akBottom]
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    Visible = False
    WordWrap = False
  end
  object ProgressBar: TProgressBar
    Left = 8
    Top = 27
    Width = 654
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
  end
  object DetailsButton: TButton
    Left = 8
    Top = 58
    Width = 105
    Height = 25
    Caption = 'Show Details'
    TabOrder = 1
    OnClick = DetailsButtonClick
  end
end
