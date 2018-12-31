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

-- define rule: *.inf
rule("wdk.inf")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".inf", ".inx")

    -- before load
    before_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")

        -- get wdk
        local wdk = target:data("wdk")
        
        -- get stampinf
        local stampinf = path.join(wdk.bindir, wdk.sdkver, arch, is_host("windows") and "stampinf.exe" or "stampinf")
        assert(stampinf and os.isexec(stampinf), "stampinf not found!")
        
        -- save uic
        target:data_set("wdk.stampinf", stampinf)
    end)

    -- on build file
    on_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- the target file
        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. ".inf")

        -- add clean files
        target:data_add("wdk.cleanfiles", targetfile)

        -- save this target file for signing (wdk.sign.*, wdk.package.* rules)
        target:data_set("wdk.sign.inf", targetfile)

        -- init args
        local args = {"-d", "*", "-a", is_arch("x64") and "amd64" or "x86", "-v", "*"}
        local flags = target:values("wdk.inf.flags", sourcefile)
        if flags then
            table.join2(args, flags)
        end
        local wdk = target:data("wdk")
        if wdk then
            if wdk.kmdfver and (target:rule("wdk.env.wdm") or target:rule("wdk.env.kmdf")) then
                table.insert(args, "-k")
                table.insert(args, wdk.kmdfver)
            elseif wdk.umdfver then
                table.insert(args, "-u")
                table.insert(args, wdk.umdfver .. ".0")
            end
        end
        table.insert(args, "-f")
        table.insert(args, targetfile)

        -- need build this object?
        local dependfile = target:dependfile(targetfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile), values = args}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%3d%%]:${dim} compiling.wdk.inf %s", opt.progress, sourcefile)
        else
            cprint("${green}[%3d%%]:${clear} compiling.wdk.inf %s", opt.progress, sourcefile)
        end

        -- get stampinf
        local stampinf = target:data("wdk.stampinf")

        -- update the timestamp
        os.cp(sourcefile, targetfile)
        os.vrunv(stampinf, args, {wildcards = false})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        dependinfo.values = args
        depend.save(dependinfo, dependfile)
    end)

