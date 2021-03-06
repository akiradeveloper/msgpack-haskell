{-# LANGUAGE OverloadedStrings #-}

import           Control.Concurrent
import           Control.Concurrent.Async
import           Control.Monad.Trans
import           Test.Tasty
import           Test.Tasty.HUnit

import           Network                       (withSocketsDo)
import           Network.MessagePackRpc.Client
import           Network.MessagePackRpc.Server

port :: Int
port = 5000

main :: IO ()
main = withSocketsDo $ defaultMain $
  testGroup "add service"
  [ testCase "correct" $ server `race_` (threadDelay 1000 >> client) ]

server :: IO ()
server =
  serve port
    [ ("add", toMethod add)
    , ("echo", toMethod echo)
    ]
  where
    add :: Int -> Int -> Method Int
    add x y = return $ x + y

    echo :: String -> Method String
    echo s = return $ "***" ++ s ++ "***"

client :: IO ()
client = execClient "localhost" port $ do
  r1 <- add 123 456
  liftIO $ r1 @?= 123 + 456
  r2 <- echo "hello"
  liftIO $ r2 @?= "***hello***"
  where
    add :: Int -> Int -> Client Int
    add = call "add"

    echo :: String -> Client String
    echo = call "echo"
