module ScenarioBuilderApp.ScenarioTree.App exposing (..)

import Api.WebGeneratedClient as Client
import Application.Type exposing (..)
import Element exposing (..)
import Element.Input as Input
import Element.Font as Font
import Http
import Page exposing (..)
import Random
import Util exposing (..)
import Uuid exposing (Uuid)
import Browser.Navigation as Navigation


-- * model


type alias Model a =
    { a
        | scenarioCollection : ScenarioCollection
        , displayedScenarioNodeMenuId : Maybe Uuid
        , environments : List Environment
        , selectedEnvironmentToRunIndex : Maybe Int
        , displayedScenarioId : Maybe Uuid
        , navigationKey : Navigation.Key
    }


-- * message


type Msg
    = ToggleFolder Uuid
    | ToggleMenu Uuid
      -- mkdir
    | GenerateRandomUUIDForFolder Uuid
    | AskMkdir Uuid Uuid
    | Mkdir Uuid Uuid
      -- create file
    | GenerateRandomUUIDForFile Uuid
    | AskTouch Uuid Uuid
    | Touch Uuid Uuid
      -- create root file
    | GenerateRandomUUIDForRootFile
    | AskTouchRoot Uuid
    | TouchRoot Uuid
      -- create root folder
    | GenerateRandomUUIDForRootFolder
    | AskMkdirRoot Uuid
    | MkdirRoot Uuid
      -- rename
    | ShowRenameInput Uuid
    | ChangeName Uuid String -- while focus is on the input
    | AskRename Uuid String -- validate input
    | Rename Uuid String -- refresh input
      -- delete
    | AskDelete Uuid
    | Delete Uuid
    | ScenarioBuilderTreeServerError



-- * update


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of


-- ** toggle builder/menu/folder


        ToggleMenu id ->
            let
                newDisplayedScenarioNodeMenuIndex =
                    case maybeExists model.displayedScenarioNodeMenuId ((==) id) of
                        True ->
                            Nothing

                        -- menu already displayed
                        False ->
                            Just id

                newModel =
                    { model
                        | displayedScenarioNodeMenuId = newDisplayedScenarioNodeMenuIndex
                    }
            in
            ( newModel, Cmd.none )

        ToggleFolder id ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode id toggleFolder) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )


-- ** mkdir


        GenerateRandomUUIDForFolder parentNodeId ->
            let
                newMsg =
                    Random.generate (AskMkdir parentNodeId) Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskMkdir parentNodeId newId ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioFolder =
                    { newScenarioFolderId = newId
                    , newScenarioFolderParentNodeId = parentNodeId
                    , newScenarioFolderName = defaultFolderName
                    }

                newMsg =
                    Client.postApiScenarioCollectionByScenarioCollectionIdScenarioFolder "" "" scenarioCollectionId newScenarioFolder (createScenarioFolderResultToMsg parentNodeId newId)
            in
            ( model, newMsg )

        Mkdir parentNodeId newId ->
            let
                (ScenarioCollection id scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode parentNodeId (mkdir newId)) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection id newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )


-- ** touch


        GenerateRandomUUIDForFile parentNodeId ->
            let
                newMsg =
                    Random.generate (AskTouch parentNodeId) Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskTouch parentNodeId newId ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioFile =
                    { newScenarioFileId = newId
                    , newScenarioFileName = defaultFileName
                    , newScenarioFileParentNodeId = parentNodeId
                    , newScenarioFileEnvironmentId = Nothing
                    }

                newMsg =
                    Client.postApiScenarioCollectionByScenarioCollectionIdScenarioFile "" "" scenarioCollectionId newScenarioFile (newScenarioFileResultToMsg parentNodeId newId)
            in
            ( model, newMsg )

        Touch parentNodeId newId ->
            let
                (ScenarioCollection id scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode parentNodeId (touch newId)) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection id newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )


-- ** rename


        ShowRenameInput id ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode id displayRenameInput) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )

        ChangeName id newName ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode id (tempRename newName)) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )

        AskRename id newName ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                payload =
                    Client.UpdateScenarioNode { updateScenarioNodeName = newName }

                newMsg =
                    Client.putApiScenarioCollectionByScenarioCollectionIdScenarioNodeByScenarioNodeId "" "" scenarioCollectionId id payload (renameNodeResultToMsg id newName)
            in
            ( model, newMsg )

        Rename id newName ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.map (modifyScenarioNode id (rename newName)) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )


-- ** delete


        AskDelete id ->
            let
                (ScenarioCollection scenarioCollectionId _) =
                    model.scenarioCollection

                newMsg =
                    Client.deleteApiScenarioCollectionByScenarioCollectionIdScenarioNodeByScenarioNodeId "" "" scenarioCollectionId id (deleteScenarioNodeResultToMsg id)
            in
            ( model, newMsg )

        Delete id ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    List.concatMap (deleteScenarioNode id) scenarioNodes

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }

                newMsg =
                    case model.displayedScenarioId == Just id of
                        True ->
                            Navigation.pushUrl model.navigationKey (href (ScenarioPage Nothing Nothing))

                        False ->
                            Cmd.none
            in
            ( newModel, newMsg )


-- ** root file


        GenerateRandomUUIDForRootFile ->
            let
                newMsg =
                    Random.generate AskTouchRoot Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskTouchRoot newId ->
            let
                (ScenarioCollection scenarioCollectionId _) =
                    model.scenarioCollection

                newRootScenarioFile =
                    { newRootScenarioFileId = newId
                    , newRootScenarioFileName = defaultFileName
                    , newRootScenarioFileEnvironmentId = Nothing
                    }

                newMsg =
                    Client.postApiScenarioCollectionByScenarioCollectionIdRootScenarioFile "" "" scenarioCollectionId newRootScenarioFile (createRootScenarioFileResultToMsg newId)
            in
            ( model, newMsg )

        TouchRoot newId ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    scenarioNodes ++ [ mkDefaultFile newId ]

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )


-- ** root folder


        GenerateRandomUUIDForRootFolder ->
            let
                newMsg =
                    Random.generate AskMkdirRoot Uuid.uuidGenerator
            in
            ( model, newMsg )

        AskMkdirRoot newId ->
            let
                (ScenarioCollection scenarioCollectionId _) =
                    model.scenarioCollection

                newRootScenarioFolder =
                    Client.NewRootScenarioFolder { newRootScenarioFolderId = newId }

                newMsg =
                    Client.postApiScenarioCollectionByScenarioCollectionIdRootScenarioFolder "" "" scenarioCollectionId newRootScenarioFolder (createRootScenarioFolderResultToMsg newId)
            in
            ( model, newMsg )

        MkdirRoot newId ->
            let
                (ScenarioCollection scenarioCollectionId scenarioNodes) =
                    model.scenarioCollection

                newScenarioNodes =
                    scenarioNodes ++ [ mkDefaultFolder newId ]

                newModel =
                    { model
                        | scenarioCollection =
                            ScenarioCollection scenarioCollectionId newScenarioNodes
                    }
            in
            ( newModel, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- * util


-- ** msg handler


renameNodeResultToMsg : Uuid -> String -> Result Http.Error () -> Msg
renameNodeResultToMsg id newName result =
    case result of
        Ok _ ->
            Rename id newName

        Err error ->
            ScenarioBuilderTreeServerError


createScenarioFolderResultToMsg : Uuid -> Uuid -> Result Http.Error () -> Msg
createScenarioFolderResultToMsg parentNodeId id result =
    case result of
        Ok _ ->
            Mkdir parentNodeId id

        Err error ->
            ScenarioBuilderTreeServerError


deleteScenarioNodeResultToMsg : Uuid -> Result Http.Error () -> Msg
deleteScenarioNodeResultToMsg id result =
    case result of
        Ok _ ->
            Delete id

        Err error ->
            ScenarioBuilderTreeServerError


newScenarioFileResultToMsg : Uuid -> Uuid -> Result Http.Error () -> Msg
newScenarioFileResultToMsg parentNodeId id result =
    case result of
        Ok _ ->
            Touch parentNodeId id

        Err error ->
            ScenarioBuilderTreeServerError


createRootScenarioFileResultToMsg : Uuid -> Result Http.Error () -> Msg
createRootScenarioFileResultToMsg id result =
    case result of
        Ok _ ->
            TouchRoot id

        Err error ->
            ScenarioBuilderTreeServerError


createRootScenarioFolderResultToMsg : Uuid -> Result Http.Error () -> Msg
createRootScenarioFolderResultToMsg id result =
    case result of
        Ok _ ->
            MkdirRoot id

        Err error ->
            ScenarioBuilderTreeServerError



-- ** tree manipulation


getScenarioNodeId : ScenarioNode -> Uuid
getScenarioNodeId scenarioNode =
    case scenarioNode of
        ScenarioFolder { id } ->
            id

        ScenarioFile { id } ->
            id

findFile : List ScenarioNode -> Uuid -> Maybe ScenarioFileRecord
findFile scenarioNodes id =
    case findNode scenarioNodes id of
        Just (ScenarioFile file) ->
            Just file

        _ ->
            Nothing

findNode : List ScenarioNode -> Uuid -> Maybe ScenarioNode
findNode scenarioNodes id =
    let
        find : ScenarioNode -> Maybe ScenarioNode
        find scenarioNode =
            case scenarioNode of
                (ScenarioFile file) as node ->
                    case file.id == id of
                        True ->
                            Just node

                        False ->
                            Nothing

                (ScenarioFolder folder) as node ->
                    case folder.id == id of
                        True ->
                            Just node

                        False ->
                            findNode folder.children id
    in
    List.head <| catMaybes (List.map find scenarioNodes)


modifyScenarioNode : Uuid -> (ScenarioNode -> ScenarioNode) -> ScenarioNode -> ScenarioNode
modifyScenarioNode id f scenarioNode =
    case getScenarioNodeId scenarioNode == id of
        True ->
            f scenarioNode

        False ->
            case scenarioNode of
                ScenarioFile scenarioFile ->
                    ScenarioFile scenarioFile

                ScenarioFolder scenarioFolder ->
                    ScenarioFolder
                        { scenarioFolder
                            | children =
                                List.map (modifyScenarioNode id f) scenarioFolder.children
                        }


deleteScenarioNode : Uuid -> ScenarioNode -> List ScenarioNode
deleteScenarioNode idToDelete scenarioNode =
    case getScenarioNodeId scenarioNode == idToDelete of
        True ->
            []

        False ->
            case scenarioNode of
                ScenarioFile scenarioFile ->
                    [ ScenarioFile scenarioFile ]

                ScenarioFolder scenarioFolder ->
                    [ ScenarioFolder
                        { scenarioFolder
                            | children =
                                List.concatMap (deleteScenarioNode idToDelete) scenarioFolder.children
                        }
                    ]


toggleFolder : ScenarioNode -> ScenarioNode
toggleFolder node =
    case node of
        (ScenarioFile _) as file ->
            file

        ScenarioFolder folder ->
            ScenarioFolder
                { folder
                    | open = not folder.open
                }


mkdir : Uuid -> ScenarioNode -> ScenarioNode
mkdir id node =
    case node of
        (ScenarioFile _) as file ->
            file

        ScenarioFolder folder ->
            ScenarioFolder
                { folder
                    | children = mkDefaultFolder id :: folder.children
                    , open = True
                }


touch : Uuid -> ScenarioNode -> ScenarioNode
touch id parentNode =
    case parentNode of
        (ScenarioFile _) as file ->
            file

        ScenarioFolder folder ->
            ScenarioFolder
                { folder
                    | children = mkDefaultFile id :: folder.children
                    , open = True
                }


displayRenameInput : ScenarioNode -> ScenarioNode
displayRenameInput node =
    case node of
        ScenarioFolder folder ->
            let
                oldValue =
                    notEditedValue folder.name
            in
            ScenarioFolder { folder | name = Edited oldValue oldValue }

        ScenarioFile file ->
            let
                oldValue =
                    notEditedValue file.name
            in
            ScenarioFile { file | name = Edited oldValue oldValue }


rename : String -> ScenarioNode -> ScenarioNode
rename newName node =
    case node of
        ScenarioFolder folder ->
            ScenarioFolder { folder | name = NotEdited newName }

        ScenarioFile file ->
            ScenarioFile { file | name = NotEdited newName }


tempRename : String -> ScenarioNode -> ScenarioNode
tempRename newName node =
    case node of
        ScenarioFolder folder ->
            ScenarioFolder { folder | name = changeEditedValue newName folder.name }

        ScenarioFile file ->
            ScenarioFile { file | name = changeEditedValue newName file.name }


mkDefaultFolder : Uuid -> ScenarioNode
mkDefaultFolder id =
    ScenarioFolder
        { id = id
        , name = NotEdited defaultFolderName
        , open = False
        , children = []
        }


mkDefaultFile : Uuid -> ScenarioNode
mkDefaultFile id =
    ScenarioFile
        { id = id
        , environmentId = NotEdited Nothing
        , name = NotEdited defaultFileName
        , scenes = []
        , whichResponseView = BodyResponseView
        }


defaultFolderName : String
defaultFolderName =
    "new folder"


defaultFileName : String
defaultFileName =
    "new scenario"



-- * view


view : Model a -> Element Msg
view model =
    let
        (ScenarioCollection _ scenarioNodes) =
            model.scenarioCollection

        mainMenuView =
            row [ spacing 10 ]
                [ Input.button []
                    { onPress = Just <| GenerateRandomUUIDForRootFolder
                    , label = iconWithText "create_new_folder" defaultFolderName
                    }
                , Input.button []
                    { onPress = Just <| GenerateRandomUUIDForRootFile
                    , label = iconWithText "note_add" defaultFileName
                    }
                ]

        treeView =
            column [ spacing 10 ] (nodeView model scenarioNodes)
    in
    column [ alignTop, spacing 20, centerX ]
        [ mainMenuView
        , treeView
        ]


nodeView : Model a -> List ScenarioNode -> List (Element Msg)
nodeView model scenarioCollection =
    case scenarioCollection of
        [] ->
            []

        node :: tail ->
            case node of
                ScenarioFolder { id, name, open, children } ->
                    let
                        folderChildrenView =
                            nodeView model children

                        tailView =
                            nodeView model tail

                        currentFolderView =
                            folderView id model name folderChildrenView open
                    in
                    currentFolderView :: tailView

                ScenarioFile { id, name } ->
                    let
                        tailView =
                            nodeView model tail

                        currentFileView =
                            fileView id model name
                    in
                    currentFileView :: tailView



-- ** file view


fileReadView : Model a -> String -> Uuid -> Element Msg
fileReadView model name id =
    let
        selected =
            model.displayedScenarioId == Just id

        color =
            case selected of
                True -> primaryColor
                False -> secondaryColor

        weight =
            case selected of
               True -> Font.heavy
               False -> Font.regular
    in
    link [ weight ]
        { url = href (ScenarioPage (Just id) Nothing)
        , label = el [] <| iconWithTextAndColor "label" name color
        }


fileEditView : String -> Uuid -> Element Msg
fileEditView name id =
    Input.text
        [ Util.onEnterWithInput (AskRename id)
        ]
        { onChange = ChangeName id
        , text = name
        , placeholder = Nothing
        , label = Input.labelHidden "rename file"
        }


fileView : Uuid -> Model a -> Editable String -> Element Msg
fileView id model name =
    let
        modeView =
            case name of
                NotEdited value ->
                    fileReadView model value id

                Edited oldValue newValue ->
                    fileEditView newValue id

        showMenu =
            model.displayedScenarioNodeMenuId == Just id

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


folderMenuView : Uuid -> Bool -> Element Msg
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


folderReadView : Uuid -> String -> Bool -> Element Msg
folderReadView id name isOpen =
    Input.button []
        { onPress = Just <| ToggleFolder id
        , label = folderWithIconView name isOpen
        }


folderEditView : Uuid -> String -> Element Msg
folderEditView id name =
    Input.text
        [ Util.onEnterWithInput (AskRename id)
        ]
        { onChange = ChangeName id
        , text = name
        , placeholder = Nothing
        , label = Input.labelHidden "rename folder"
        }


folderView : Uuid -> Model a -> Editable String -> List (Element Msg) -> Bool -> Element Msg
folderView id model name folderChildrenView open =
    let
        modeView =
            case name of
                NotEdited value ->
                    folderReadView id value open

                Edited oldValue newValue ->
                    folderEditView id newValue

        showMenu =
            Just id == model.displayedScenarioNodeMenuId
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
