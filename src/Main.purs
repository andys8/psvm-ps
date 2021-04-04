module Main where

import Prelude

import ArgParse.Basic (ArgParser, anyNotFlag, boolean, choose, command, flag, flagHelp, flagInfo, parseArgs, printArgError)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Console as Console
import Node.Process as Process
import Psvm.Ls as Ls
import Psvm.Version (Version)
import Psvm.Version as Version

{-----------------------------------------------------------------------}

data Command
  = Install (Maybe Version)
  | Uninstall (Maybe Version)
  | Use (Maybe Version)
  | Ls { remote :: Boolean }

derive instance genericCommand :: Generic Command _

instance showCommand :: Show Command where
  show = genericShow


commandParser :: ArgParser Command
commandParser =
  choose "command"
  [ command [ "install" ] "Install a PureScript version." $
      flagHelp *> anyNotFlag "VERSION" "version to install"
        <#> Install <<< Version.fromString

  , command [ "uninstall" ] "Uninstall a PureScript version." $
      flagHelp *> anyNotFlag "VERSION" "version to uninstall"
        <#> Uninstall <<< Version.fromString

  , command [ "use" ] "Use a PureScript version." $
      flagHelp *> anyNotFlag "VERSION" "version to use"
        <#> Use <<< Version.fromString

  , command [ "ls" ] "List PureScript versions." $
      flagHelp *>
        ( flag [ "-r", "--remote" ] "List remote versions?" # boolean )
          <#> \remote -> Ls { remote }
  ]

{-----------------------------------------------------------------------}

perform :: Array String -> Effect Unit
perform argv =
  case parseArgs name about parser argv of

    Left e ->
      Console.log $ printArgError e

    Right c -> do
      mHome <- Process.lookupEnv "HOME"

      case mHome of
        Nothing -> do
          Console.error "Fatal: unset HOME"
          Process.exit 1
        Just home -> do
          let psvm = getPsvmFolder home
          performCommand psvm c
  where
    performCommand psvm =
      case _ of
        Ls { remote }
          | remote    -> Ls.printRemote
          | otherwise -> Ls.printLocal psvm

        c ->
          Console.logShow c *> Process.exit 0


parser :: ArgParser Command
parser =
  flagHelp *> versionFlag *> commandParser

  where
    versionFlag =
      flagInfo [ "-v", "--versions" ]
        "Show the installed psvm-ps version." version

{-----------------------------------------------------------------------}

name :: String
name = "psvm-ps"


version :: String
version = "psvm-ps - v0.1.0"


about :: String
about = "PureScript version management in PureScript."


main :: Effect Unit
main = do
  cwd <- Process.cwd
  argv <- Array.drop 2 <$> Process.argv
  perform argv
