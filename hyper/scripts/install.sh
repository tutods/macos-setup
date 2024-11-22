#!/bin/bash
if ! brew list | grep -q hyper; then
  brew install --cask hyper
fi