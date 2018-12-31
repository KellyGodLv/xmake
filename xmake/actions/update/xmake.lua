--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define task
task("update")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake update [options] [version]"

                -- description
            ,   description = "Update and uninstall the xmake program."

                -- options
            ,   options = 
                {
                    {nil, "uninstall",  "k",  nil,    "Uninstall the current xmake program."                }
                ,   {                                                                                       }
                ,   {nil, "xmakever",    "v",  nil,   "The given xmake version. (e.g. ~2.2.3, dev, master)" }
                }
            }



