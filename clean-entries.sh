#!/bin/bash

sqlite3 tickets.sqlite < fix-province-entries.sql
