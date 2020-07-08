module PGBuilderApp.PGTree.App exposing (..)

--import PGBuilderApp.PGBuilder.App as PGBuilder

import Animation
import Api.WebGeneratedClient as Client
import Application.Type exposing (..)
import Element exposing (..)
import Element.Input as Input
import Http
import Page exposing (..)
import Random
import Util exposing (..)
import Uuid



-- * model


type alias Model a =
    { a
        | pgCollection : PgCollection
        , displayedPgNodeMenuId : Maybe Uuid.Uuid
        , environments : List Environment
        , selectedEnvironmentToRunIndex : Maybe Int
    }



-- * message


type Msg
    = ToggleFolder Uuid.Uuid
    | ToggleMenu Uuid.Uuid
      -- mkdir
    | GenerateRandomUUIDForFolder Uuid.Uuid
    | AskMkdir Uuid.Uuid Uuid.Uuid
    | Mkdir Uuid.Uuid Uuid.Uuid
      -- create file
    | GenerateRandomUUIDForFile Uuid.Uuid
    | AskTouch Uuid.Uuid Uuid.Uuid
    | Touch Uuid.Uuid Uuid.Uuid
      -- create root file
    | GenerateRandomUUIDForRootFile
    | AskTouchRoot Uuid.Uuid
    | TouchRoot Uuid.Uuid
      -- create root folder
    | GenerateRandomUUIDForRootFolder
    | AskMkdirRoot Uuid.Uuid
    | MkdirRoot Uuid.Uuid
      -- rename
    | ShowRenameInput Uuid.Uuid
    | ChangeName Uuid.Uuid String -- while focus is on the input
    | AskRename Uuid.Uuid String -- validate input
    | Rename Uuid.Uuid String -- refresh input
      -- delete
    | AskDelete Uuid.Uuid
    | Delete Uuid.Uuid
    | BuilderTreeServerError



-- * update


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        ToggleMenu id ->
            let
                newDisplayedPgNodeMenuIndex =
                    case maybeExists model.displayedPgNodeMenuId ((==) id) of
                        True ->
                            Nothing

                        -- menu already displayed
                        False ->
                            Just id

                newModel =
                    { model
                        | displayedPgNodeMenuId = newDisplayedPgNodeMenuIndex
                    }
            in
            ( newModel, Cmd.none )

        ToggleFolder id ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode id toggleFolder) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        GenerateRandomUUIDForFolder parentNodeId ->
            let
                newMsg =
                    Random.generate (AskMkdir parentNodeId) Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskMkdir parentNodeId newId ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgFolder =
                    { newPgFolderId = newId
                    , newPgFolderParentNodeId = parentNodeId
                    , newPgFolderName = "new folder"
                    }

                newMsg =
                    Client.postApiPgCollectionByPgCollectionIdPgFolder "" "" pgCollectionId newPgFolder (createPgFolderResultToMsg parentNodeId newId)
            in
            ( model, newMsg )

        Mkdir parentNodeId newId ->
            let
                (PgCollection id pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode parentNodeId (mkdir newId)) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection id newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        GenerateRandomUUIDForFile parentNodeId ->
            let
                newMsg =
                    Random.generate (AskTouch parentNodeId) Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskTouch parentNodeId newId ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgFile =
                    { newPgFileId = newId
                    , newPgFileParentNodeId = parentNodeId
                    , newPgFileName = "new pg file"
                    , newPgFileSql = ""
                    }

                newMsg =
                    Client.postApiPgCollectionByPgCollectionIdPgFile "" "" pgCollectionId newPgFile (newPgFileResultToMsg parentNodeId newId)
            in
            ( model, newMsg )

        Touch parentNodeId newId ->
            let
                (PgCollection id pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode parentNodeId (touch newId)) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection id newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        ShowRenameInput id ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode id displayRenameInput) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        ChangeName id newName ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode id (tempRename newName)) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        AskRename id newName ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                payload =
                    Client.UpdatePgNode { updatePgNodeName = newName }

                newMsg =
                    Client.putApiPgCollectionByPgCollectionIdPgNodeByPgNodeId "" "" pgCollectionId id payload (renameNodeResultToMsg id newName)
            in
            ( model, newMsg )

        Rename id newName ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.map (modifyPgNode id (rename newName)) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        AskDelete id ->
            let
                (PgCollection pgCollectionId _) =
                    model.pgCollection

                newMsg =
                    Client.deleteApiPgCollectionByPgCollectionIdPgNodeByPgNodeId "" "" pgCollectionId id (deletePgNodeResultToMsg id)
            in
            ( model, newMsg )

        Delete id ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    List.concatMap (deletePgNode id) pgNodes

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        GenerateRandomUUIDForRootFile ->
            let
                newMsg =
                    Random.generate AskTouchRoot Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskTouchRoot newId ->
            let
                (PgCollection pgCollectionId _) =
                    model.pgCollection

                newRootPgFile =
                    { newRootPgFileId = newId
                    , newRootPgFileName = "new pg file"
                    , newRootPgFileSql = ""
                    }

                newMsg =
                    Client.postApiPgCollectionByPgCollectionIdRootPgFile "" "" pgCollectionId newRootPgFile (createRootPgFileResultToMsg newId)
            in
            ( model, newMsg )

        TouchRoot newId ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    pgNodes ++ [ mkDefaultFile newId ]

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        GenerateRandomUUIDForRootFolder ->
            let
                newMsg =
                    Random.generate AskMkdirRoot Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskMkdirRoot newId ->
            let
                (PgCollection pgCollectionId _) =
                    model.pgCollection

                newRootPgFolder =
                    { newRootPgFolderId = newId
                    , newRootPgFolderName = "new pg folder"
                    }

                newMsg =
                    Client.postApiPgCollectionByPgCollectionIdRootPgFolder "" "" pgCollectionId newRootPgFolder (createRootPgFolderResultToMsg newId)
            in
            ( model, newMsg )

        MkdirRoot newId ->
            let
                (PgCollection pgCollectionId pgNodes) =
                    model.pgCollection

                newPgNodes =
                    pgNodes ++ [ mkDefaultFolder newId ]

                newModel =
                    { model
                        | pgCollection =
                            PgCollection pgCollectionId newPgNodes
                    }
            in
            ( newModel, Cmd.none )

        BuilderTreeServerError ->
            Debug.todo "error with builder tree"


-- * util


-- ** msg handler


renameNodeResultToMsg : Uuid.Uuid -> String -> Result Http.Error () -> Msg
renameNodeResultToMsg id newName result =
    case result of
        Ok _ ->
            Rename id newName

        Err error ->
            BuilderTreeServerError


createPgFolderResultToMsg : Uuid.Uuid -> Uuid.Uuid -> Result Http.Error () -> Msg
createPgFolderResultToMsg parentNodeId id result =
    case result of
        Ok _ ->
            Mkdir parentNodeId id

        Err error ->
            BuilderTreeServerError


deletePgNodeResultToMsg : Uuid.Uuid -> Result Http.Error () -> Msg
deletePgNodeResultToMsg id result =
    case result of
        Ok _ ->
            Delete id

        Err error ->
            BuilderTreeServerError


newPgFileResultToMsg : Uuid.Uuid -> Uuid.Uuid -> Result Http.Error () -> Msg
newPgFileResultToMsg parentNodeId id result =
    case result of
        Ok _ ->
            Touch parentNodeId id

        Err error ->
            BuilderTreeServerError


createRootPgFileResultToMsg : Uuid.Uuid -> Result Http.Error () -> Msg
createRootPgFileResultToMsg id result =
    case result of
        Ok _ ->
            TouchRoot id

        Err error ->
            BuilderTreeServerError


createRootPgFolderResultToMsg : Uuid.Uuid -> Result Http.Error () -> Msg
createRootPgFolderResultToMsg id result =
    case result of
        Ok _ ->
            MkdirRoot id

        Err error ->
            BuilderTreeServerError



-- ** tree manipulation


getPgNodeId : PgNode -> Uuid.Uuid
getPgNodeId pgNode =
    case pgNode of
        PgFolder { id } ->
            id

        PgFile { id } ->
            id


modifyPgNode : Uuid.Uuid -> (PgNode -> PgNode) -> PgNode -> PgNode
modifyPgNode id f pgNode =
    case getPgNodeId pgNode == id of
        True ->
            f pgNode

        False ->
            case pgNode of
                PgFile pgFile ->
                    PgFile pgFile

                PgFolder pgFolder ->
                    PgFolder
                        { pgFolder
                            | children =
                                List.map (modifyPgNode id f) pgFolder.children
                        }


deletePgNode : Uuid.Uuid -> PgNode -> List PgNode
deletePgNode idToDelete pgNode =
    case getPgNodeId pgNode == idToDelete of
        True ->
            []

        False ->
            case pgNode of
                PgFile pgFile ->
                    [ PgFile pgFile ]

                PgFolder pgFolder ->
                    [ PgFolder
                        { pgFolder
                            | children =
                                List.concatMap (deletePgNode idToDelete) pgFolder.children
                        }
                    ]


toggleFolder : PgNode -> PgNode
toggleFolder node =
    case node of
        (PgFile _) as file ->
            file

        PgFolder folder ->
            PgFolder
                { folder
                    | open = not folder.open
                }


mkdir : Uuid.Uuid -> PgNode -> PgNode
mkdir id node =
    case node of
        (PgFile _) as file ->
            file

        PgFolder folder ->
            PgFolder
                { folder
                    | children = mkDefaultFolder id :: folder.children
                    , open = True
                }


touch : Uuid.Uuid -> PgNode -> PgNode
touch id parentNode =
    case parentNode of
        (PgFile _) as file ->
            file

        PgFolder folder ->
            PgFolder
                { folder
                    | children = mkDefaultFile id :: folder.children
                    , open = True
                }


displayRenameInput : PgNode -> PgNode
displayRenameInput node =
    case node of
        PgFolder folder ->
            let
                oldValue =
                    notEditedValue folder.name
            in
            PgFolder { folder | name = Edited oldValue oldValue }

        PgFile file ->
            let
                oldValue =
                    notEditedValue file.name
            in
            PgFile { file | name = Edited oldValue oldValue }


rename : String -> PgNode -> PgNode
rename newName node =
    case node of
        PgFolder folder ->
            PgFolder { folder | name = NotEdited newName }

        PgFile file ->
            PgFile { file | name = NotEdited newName }


tempRename : String -> PgNode -> PgNode
tempRename newName node =
    case node of
        PgFolder folder ->
            PgFolder { folder | name = changeEditedValue newName folder.name }

        PgFile file ->
            PgFile { file | name = changeEditedValue newName file.name }


mkDefaultFolder : Uuid.Uuid -> PgNode
mkDefaultFolder id =
    PgFolder
        { id = id
        , name = NotEdited "new folder"
        , open = False
        , children = []
        }


mkDefaultFile : Uuid.Uuid -> PgNode
mkDefaultFile id =
    PgFile
        { id = id
        , name = NotEdited "new pg file"
        , sql = NotEdited ""
        , pgComputation = Nothing
        , showResponseView = False
        }


-- * view


view : Model a -> Element Msg
view model =
    let
        (PgCollection _ pgNodes) =
            model.pgCollection

        mainMenuView =
            row [ spacing 10 ]
                [ Input.button []
                    { onPress = Just <| GenerateRandomUUIDForRootFolder
                    , label = iconWithText "create_new_folder" "new folder"
                    }
                , Input.button []
                    { onPress = Just <| GenerateRandomUUIDForRootFile
                    , label = iconWithText "note_add" "new pg"
                    }
                ]

        treeView =
            column [ spacing 10 ] (nodeView model.displayedPgNodeMenuId pgNodes)
    in
    column [ alignTop, spacing 20, centerX ]
        [ mainMenuView
        , treeView
        ]


nodeView : Maybe Uuid.Uuid -> List PgNode -> List (Element Msg)
nodeView mDisplayedPgNodeMenuIndex pgCollection =
    case pgCollection of
        [] ->
            []

        node :: tail ->
            case node of
                PgFolder { id, name, open, children } ->
                    let
                        folderChildrenView =
                            nodeView mDisplayedPgNodeMenuIndex children

                        tailView =
                            nodeView mDisplayedPgNodeMenuIndex tail

                        currentFolderView =
                            folderView id mDisplayedPgNodeMenuIndex name folderChildrenView open
                    in
                    currentFolderView :: tailView

                PgFile { id, name } ->
                    let
                        tailView =
                            nodeView mDisplayedPgNodeMenuIndex tail

                        currentFileView =
                            fileView id mDisplayedPgNodeMenuIndex name
                    in
                    currentFileView :: tailView



-- ** file view


fileReadView : String -> Uuid.Uuid -> Element Msg
fileReadView name id =
    link []
        { url = href (PgPage (Just id))
        , label = el [] <| iconWithTextAndColor "label" name secondaryColor
        }


fileEditView : String -> Uuid.Uuid -> Element Msg
fileEditView name id =
    Input.text
        [ Util.onEnterWithInput (AskRename id)
        ]
        { onChange = ChangeName id
        , text = name
        , placeholder = Nothing
        , label = Input.labelHidden "rename file"
        }


fileView : Uuid.Uuid -> Maybe Uuid.Uuid -> Editable String -> Element Msg
fileView id mDisplayedPgNodeMenuIndex name =
    let
        modeView =
            case name of
                NotEdited value ->
                    fileReadView value id

                Edited oldValue newValue ->
                    fileEditView newValue id

        showMenu =
            mDisplayedPgNodeMenuIndex == Just id

        menuView =
            case not showMenu of
                True ->
                    none

                False ->
                    row []
                        [ Input.button []
                            { onPress = Just <| ShowRenameInput id
                            , label = editIcon
                            }
                        , Input.button []
                            { onPress = Just <| AskDelete id
                            , label = deleteIcon
                            }
                        ]
    in
    row []
        [ modeView
        , Input.button []
            { onPress = Just <| ToggleMenu id
            , label =
                icon <|
                    case showMenu of
                        True ->
                            "more_horiz"

                        False ->
                            "more_vert"
            }
        , menuView
        ]



-- ** folder view


folderWithIconView : String -> Bool -> Element Msg
folderWithIconView name isOpen =
    let
        folderIconText =
            case isOpen of
                False ->
                    "keyboard_arrow_right"

                True ->
                    "keyboard_arrow_down"
    in
    iconWithText folderIconText name


folderMenuView : Uuid.Uuid -> Bool -> Element Msg
folderMenuView id isOpen =
    let
        iconClass =
            case isOpen of
                True ->
                    "more_horiz"

                False ->
                    "more_vert"

        menuIcon =
            icon iconClass

        menuView =
            row [ spacing 5 ]
                [ Input.button []
                    { onPress = Just <| ShowRenameInput id
                    , label = editIcon
                    }
                , Input.button []
                    { onPress = Just <| GenerateRandomUUIDForFolder id
                    , label = createFolderIcon
                    }
                , Input.button []
                    { onPress = Just <| GenerateRandomUUIDForFile id
                    , label = createFileIcon
                    }
                , Input.button []
                    { onPress = Just <| AskDelete id
                    , label = deleteIcon
                    }
                ]
    in
    case isOpen of
        True ->
            row [] [ menuIcon, menuView ]

        False ->
            row [] [ menuIcon ]


folderReadView : Uuid.Uuid -> String -> Bool -> Element Msg
folderReadView id name isOpen =
    Input.button []
        { onPress = Just <| ToggleFolder id
        , label = folderWithIconView name isOpen
        }


folderEditView : Uuid.Uuid -> String -> Element Msg
folderEditView id name =
    Input.text
        [ Util.onEnterWithInput (AskRename id)
        ]
        { onChange = ChangeName id
        , text = name
        , placeholder = Nothing
        , label = Input.labelHidden "rename folder"
        }


folderView : Uuid.Uuid -> Maybe Uuid.Uuid -> Editable String -> List (Element Msg) -> Bool -> Element Msg
folderView id mDisplayedPgNodeMenuIndex name folderChildrenView open =
    let
        modeView =
            case name of
                NotEdited value ->
                    folderReadView id value open

                Edited oldValue newValue ->
                    folderEditView id newValue

        showMenu =
            Just id == mDisplayedPgNodeMenuIndex
    in
    column [ width (fill |> maximum 300) ]
        [ row []
            [ modeView
            , Input.button []
                { onPress = Just <| ToggleMenu id
                , label = folderMenuView id showMenu
                }
            ]
        , case open of
            True ->
                column [ spacing 10, paddingXY 20 10 ] folderChildrenView

            False ->
                none
        ]