%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% rebar: Erlang Build Tools
%%
%% Copyright (c) 2009 Dave Smith (dizzyd@dizzyd.com),
%%                    Tim Dysinger (tim@dysinger.net)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -------------------------------------------------------------------

-module(rebar_lfe_compiler).

-export([compile/2]).

-include("rebar.hrl").

%% ===================================================================
%% Public API
%% ===================================================================

compile(Config, _AppFile) ->
    ?DEPRECATED(fail_on_warning, warnings_as_errors,
                rebar_config:get_list(Config, lfe_opts, []),
                "once OTP R15 is released"),

    FirstFiles = rebar_config:get_list(Config, lfe_first_files, []),
    rebar_base_compiler:run(Config, FirstFiles, "src", ".lfe", "ebin", ".beam",
                            fun compile_lfe/3).

%% ===================================================================
%% Internal functions
%% ===================================================================

compile_lfe(Source, Target, Config) ->
    case code:which(lfe_comp) of
        non_existing ->
            ?CONSOLE(<<
                       "~n"
                       "*** MISSING LFE COMPILER ***~n"
                       "  You must do one of the following:~n"
                       "    a) Install LFE globally in your erl libs~n"
                       "    b) Add LFE as a dep for your project, eg:~n"
                       "       {lfe, \"0.6.1\",~n"
                       "        {git, \"git://github.com/rvirding/lfe\",~n"
                       "         {tag, \"v0.6.1\"}}}~n"
                       "~n"
                     >>, []),
            ?FAIL;
        _ ->
            Opts = [{i, "include"}, {outdir, "ebin"}, report, return] ++
                rebar_config:get_list(Config, lfe_opts, []),
            case lfe_comp:file(Source, Opts) of
                {ok, _, []} ->
                    ok;
                {ok, _, _Warnings} ->
                    case lists:member(fail_on_warning, Opts) of
                        true ->
                            ok = file:delete(Target),
                            ?FAIL;
                        false ->
                            ok
                    end;
                _ ->
                    ?FAIL
            end
    end.
