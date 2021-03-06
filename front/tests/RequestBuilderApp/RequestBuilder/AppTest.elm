module RequestBuilderApp.RequestBuilder.AppTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import RequestBuilderApp.RequestBuilder.App exposing (..)
import Application.Type exposing(..)
import RequestComputation exposing(..)

suite : Test
suite =
    describe "implement this" <|
        [ test "please" <|
              \_ -> Expect.equal True True
        ]

    {-
    describe "BuilderApp.Builder.App module"
        [ describe "when building request"
            [ test "remove http from url" <|
                \_ ->
                  Expect.equal (removeSchemeFromUrl "http://foo.com") "foo.com"

            , test "remove https from url" <|
                \_ ->
                  Expect.equal (removeSchemeFromUrl "https://foo.com") "foo.com"

            , test "don't remove http when url is malformed" <|
                \_ ->
                  Expect.equal (removeSchemeFromUrl "http:/ /foo.com") "http:/ /foo.com"

            , test "don't touch when url doesn't have a scheme" <|
                \_ ->
                  Expect.equal (removeSchemeFromUrl "foo.com") "foo.com"
            ]

        , describe "Interpolation"
            [ test "do nothing when there are no variables" <|
                  \_ ->
                      let
                          keyValues : List (Storable NewKeyValue KeyValue)
                          keyValues =
                              [ New { key = "key1"
                                    , value = [ Sentence "value1" ]
                                    }
                              ]
                      in
                          Expect.equal (interpolate keyValues "howdy how is it going ?") "howdy how is it going ?"

            , test "do nothing when there are no key values" <|
                  \_ ->
                  Expect.equal (interpolate [] "{{user}}") "{{user}}"

            , test "interpolate variables when they are available" <|
                  \_ ->
                      let
                          keyValues : List (Storable NewKeyValue KeyValue)
                          keyValues =
                              [ New { key = "firstname"
                                    , value = [ Sentence "John" ]
                                    }
                              , New { key = "lastname"
                                    , value = [ Sentence "Doe" ]
                                    }
                              , New { key = "age"
                                    , value = [ Sentence "10" ]
                                    }
                              ]
                      in
                          Expect.equal (interpolate keyValues "hello {{firstname}} {{lastname}} !") "hello John Doe !"

            , test "interpolate variables with weird format" <|
                  \_ ->
                      let
                          keyValues : List (Storable NewKeyValue KeyValue)
                          keyValues =
                              [ New { key = "john-doe1"
                                    , value = [ Sentence "John" ]
                                    }
                              ]
                      in
                          Expect.equal (interpolate keyValues "hello {{john-doe1}} !") "hello John !"

            , test "interpolate with multiline strings" <|
                  \_ ->
                      let
                          keyValues : List (Storable NewKeyValue KeyValue)
                          keyValues =
                              [ New { key = "firstname"
                                    , value = [ Sentence "John" ]
                                    }
                              , New { key = "lastname"
                                    , value = [ Sentence "Doe" ]
                                    }
                              ]

                          body = """hello {{firstname}} !
is your lastname: {{lastname}} ?
"""

                          expectedRes = """hello John !
is your lastname: Doe ?
"""
                      in
                          Expect.equal (interpolate keyValues body) expectedRes

            , test "don't mess up with brackets" <|
                  \_ ->
                      let
                          keyValues : List (Storable NewKeyValue KeyValue)
                          keyValues =
                              [ New { key = "firstname"
                                    , value = [ Sentence "John" ]
                                    }
                              , New { key = "lastname"
                                    , value = [ Sentence "Doe" ]
                                    }
                              ]

                          input =
                              "{hello} {{{firstname}}} {{}} {{ }} {{lastname}} !"

                          expectedRes =
                              "{hello} {John} {{}} {{ }} Doe !"

                      in
                          Expect.equal (interpolate keyValues input) expectedRes
            ]
        ]
-}
