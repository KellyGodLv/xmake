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

-- define rule: tracewpp
rule("wdk.tracewpp")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- before load
    before_load(function (target)

        -- imports
        import("core.project.config")

        -- get wdk
        local wdk = target:data("wdk")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get tracewpp
        local tracewpp = path.join(wdk.bindir, arch, is_host("windows") and "tracewpp.exe" or "tracewpp")
        if not os.isexec(tracewpp) then
            tracewpp = path.join(wdk.bindir, wdk.sdkver, arch, is_host("windows") and "tracewpp.exe" or "tracewpp")
        end
        assert(os.isexec(tracewpp), "tracewpp not found!")
        
        -- save tracewpp
        target:data_set("wdk.tracewpp", tracewpp)

        -- save output directory
        target:data_set("wdk.tracewpp.outputdir", path.join(config.buildir(), ".wdk", "wpp", config.get("mode") or "generic", config.get("arch") or os.arch(), target:name()))
        
        -- save config directory
        target:data_set("wdk.tracewpp.configdir", path.join(wdk.bindir, wdk.sdkver, "WppConfig", "Rev1"))
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- get tracewpp
        local tracewpp = target:data("wdk.tracewpp")

        -- get outputdir
        local outputdir = target:data("wdk.tracewpp.outputdir")

        -- get configdir
        local configdir = target:data("wdk.tracewpp.configdir")

        -- init args
        local args = {}
        if target:rule("wdk.driver") and (target:rule("wdk.env.kmdf") or target:rule("wdk.env.wdm")) then
            table.insert(args, "-km")
            table.insert(args, "-gen:{km-WdfDefault.tpl}*.tmh")
        end
        local flags = target:values("wdk.tracewpp.flags", sourcefile)
        if flags then
            table.join2(args, flags)
        end
        table.insert(args, "-cfgdir:" .. configdir)
        table.insert(args, "-odir:" .. outputdir)
        table.insert(args, sourcefile)

        -- add includedirs
        target:add("includedirs", outputdir)

        -- add clean files
        target:data_add("wdk.cleanfiles", outputdir)

        -- need build this object?
        local targetfile = path.join(outputdir, path.basename(sourcefile) .. ".tmh")
        local dependfile = target:dependfile(targetfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile), values = args}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%3d%%]:${dim} compiling.wdk.tracewpp %s", opt.progress, sourcefile)
        else
            cprint("${green}[%3d%%]:${clear} compiling.wdk.tracewpp %s", opt.progress, sourcefile)
        end

        -- ensure the output directory
        if not os.isdir(outputdir) then
            os.mkdir(outputdir)
        end

        -- remove the previous target file first
        os.tryrm(targetfile)

        -- generate the *.tmh file
        os.vrunv(tracewpp, args, {wildcards = false})

        -- update files and values to the dependent file
        dependinfo.files  = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
    end)

