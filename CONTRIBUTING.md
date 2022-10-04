# Contributing to Luxart Vehicle Control

:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

#### Table Of Contents

[Code of Conduct](#code-of-conduct)

[What should I know before I get started?](#what-should-i-know-before-i-get-started)
  * [File & Folder Structure](#file--folder-structure)
  * [Naming Conventions](#naming-conventions)

[How Can I Contribute?](#how-can-i-contribute)
  * [Reporting Bugs](#reporting-bugs)
  * [Suggesting Enhancements](#suggesting-enhancements)
  * [Your First Code Contribution](#your-first-code-contribution)
  * [Pull Requests](#pull-requests)

## Code of Conduct

This project and everyone participating in it is governed by the [Luxart Vehicle Control Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to TheDude#9205 on Discord.

## What should I know before I get started?

### File & Folder Structure
Luxart Vehicle Control is a large complex resource with many folders and file names, it is important to understand these to make your life easier and maintain uniformity within the code base. 

#### Folders: All sub folder, excluding HTML/NUI folder should be upper-case.
* `/lvc_v3/*` files located in the root resource folder are strictly for user configuration and setup.  
* `/lvc_v3/UTIL/*` contains files related to the base resources core functions and features organized by file name.
* `/lvc_v3/UI/**/*` contains files related to base resources RageUI menu, front end messages, and Javascript audio / visual notifications.
* `/lvc_v3/PLUGINS/*` contains shared plugin functions, menus, and UI code following file structure below, in addition to plugin folders.
* `/lvc_v3/PLUGINS/**/*` contain functionality related to the specific plugins functions, events, and resources required for that plugin. 
* `/dependencies/` contains required files or resources for LVCs operation. The included RageUI dependency has been modified and should be used over the original developers code.

#### Files: All configuration files should be upper-case. All other files should be lower case and words should be separated by single underscores. *(e.g. 'cl_auto_extras')*
* Client & Server files distinction
    * All files, excluding user configuration files *(e.g. 'SETTINGS', 'SIRENS')* should be prefixed by their associated client / server side.
        * `cl_` a client side script
        * `sv_` a server side script
        * `sh_` a shared script accessible by client and server *(should be avoided)*
    * Organization file names
        * `cl_ragemenu` contains RageUI menu implementations and functions specific to the menus included. The specific menu can be extrapolated by its location *(e.g. `/UI/cl_ragemenu` contains base resource menu, `/PLUGINS/cl_ragemenu` contains plugins menu, `/PLUGINS/<PLUGIN>/UI/cl_ragemenu/` contains menu items for that plugins sub menu)*.
	* `cl_utils` contains shared, abstract, functions that can convolute other files where called. There really shouldn't be another implementation of cl_utils. Plugin code should be encapsulated into a single file.
        * `cl_storage` contains code specific to saving, loading, and interpreting saved/loaded data. This should be included in plugins if data should be saved to KVPs.
        * `cl_hud` contains shared code regarding GTA V front end messages, JS call backs and events, and HUD variables. This should be included in plugins if it has custom UI/HUD integration.
	* `cl_<plugin>` contains all client side plugin code.
	* `sv_<plugin>` contains all server side plugin code.
	* `sv_version` is a templated files for version checking and reporting of installed plugins.
		
### Naming Conventions
#### Variables should be...
* snake case, seperated by '_' under-scores not camel case ('camelCase')
* descriptive in nature, down to a phrase separated by underscores. *(e.g. `player_is_emerg_driver`)
* all upper-case if a configuration table or name-space, selective upper case for acronym, otherwise lower-case.
* prefixed or postfixed by `default` if a configuration variable that can be changed and saved by end user.
* if confusing and similar prefixed or postfixed by a common group name *(e.g. tone_PMANU_id, tone_MAIN_MEM_id)*

#### Functions should...
* start with capital letter and have a capital letter for each new word. *(e.g. `TogTkdState(), `SetSfxSchemeIndex()`)* 
* be prefixed by `<namespace>:` if specific to that plugin or UTIL, UI, Storage.
* be prefixed by common prefixes `Tog` *(toggle)*, `Set`, `Get`, `Update`, or another appropriate verb if possible. 
* contain descriptive parameter names *('tone_index', 'tone_id', `profile_string`)*

#### Event Names...
* should be prefixed by their respective name-space if possible, otherwise `'lvc:'`.
* should be postfixed by their respective side *(client = `_c`, server = `_s`)*  *(e.g. 'lvc:SetLxSirenState_s)*
* follow all other function requirements above. 

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for LVC. Following these guidelines helps maintainers and the community understand your report :pencil:, reproduce the behavior :computer: :computer:, and find related reports :mag_right:.

When you are creating a bug report, please [include as many details as possible](#how-do-i-submit-a-good-bug-report). 

> **Note:** If you find a **Closed** issue that seems like it is the same thing that you're experiencing, open a new issue and include a link to the original issue in the body of your new one.

#### Before Submitting A Bug Report

* **Perform a [cursory search](https://github.com/TrevorBarns/luxart-vehicle-control/issues?q=is%3Aissue)** to see if the problem has already been reported. If it has **and the issue is still open**, add a comment to the existing issue instead of opening a new one.

#### How Do I Submit A (Good) Bug Report?

Bugs are tracked as [GitHub issues](https://guides.github.com/features/issues/).

Explain the problem and include additional details to help maintainers reproduce the problem:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible. When listing steps, **don't just say what you did, but explain how you did it**. 
* **Provide specific examples to demonstrate the steps**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem. You can use [this tool](https://www.cockos.com/licecap/) to record GIFs.
* **If you're reporting that LVC crashed**, include a copy of the respective client log found `AppData/Local/FiveM/FiveM.app/logs`, server dump file found in `/FXServer/crashes/`, or server log by [copy text from CMD](https://stackoverflow.com/questions/11543578/copy-text-from-a-windows-cmd-window-to-clipboard). 
* **If the problem wasn't triggered by a specific action**, describe what you were doing before the problem happened and share more information using the guidelines below.

Provide more context by answering these questions:

* **Can you reproduce the problem after disabling other resources?**
* **Did the problem start happening recently** (e.g. after updating to a new version of LVC) or was this always a problem?
* If the problem started happening recently, **can you reproduce the problem in an older version of LVC?** What's the most recent version in which the problem doesn't happen? You can download older versions of LVC from [the releases page](https://github.com/luxart-vehicle-control/releases).
* **Can you reliably reproduce the issue?** If not, provide details about how often the problem happens and under which conditions it normally happens.
* If the problem is related to working with files (e.g. opening and editing files), **does the problem happen for all files and projects or only some?** Does the problem happen only when working with local or remote files (e.g. on network drives), with files of a specific type (e.g. only JavaScript or Python files), with large files or files with very long lines, or with files in a specific encoding? Is there anything else special about the files you are using?

Include details about your configuration and environment:

* **Which version of LVC are you using?** You can get the exact version by clicking "More Information" in game or viewing server console on startup.
* **What's the OS is the FiveM server running on**?
* **Do you know what version server artifacts you are running** If not, you can find it by viewing `<server ip>:30120/info.json` under `"server":"FXServer-master SERVER v1.0.0.<artifacts> <os>"` or run the `version` command in the server console.
* **Which [plugins](https://github.com/TrevorBarns/luxart-vehicle-control/tree/master/PLUGINS) do you have installed?**

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for LVC, including completely new features and minor improvements to existing functionality. Following these guidelines helps maintainers and the community understand your suggestion :pencil: and find related suggestions :mag_right:.

When you are creating an enhancement suggestion, please [include as many details as possible](#how-do-i-submit-a-good-enhancement-suggestion). 

#### Before Submitting An Enhancement Suggestion

* **Check if there's already [a plugin](https://github.com/TrevorBarns/luxart-vehicle-control/tree/master/PLUGINS) which provides that enhancement.**
* **Perform a [cursory search](https://github.com/TrevorBarns/luxart-vehicle-control/issues?q=is%3Aissue)**  to see if the enhancement has already been suggested. If it has, add a comment to the existing issue instead of opening a new one.

#### How Do I Submit A (Good) Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](https://guides.github.com/features/issues/). Create an issue on that repository and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Include screenshots and animated GIFs** which help you demonstrate the steps or point out the part of LVC which the suggestion is related to. You can use [this tool](https://www.cockos.com/licecap/) to record GIFs.
* **Explain why this enhancement would be useful** to most LVC users. Do you think it would be best as a base LVC enhancement, plugin enhancement, or new plugin?
* **Specify which version of LVC you're using.** You can get the exact version by clicking "More Information" in game or viewing server console on startup.

### Your First Code Contribution

Unsure where to begin contributing to LVC? You can start by looking through these `beginner` and `help-wanted` issues:

* Beginner issues - issues which should only require a few lines of code, and a test or two.
* Help wanted issues - issues which should be a bit more involved than `beginner` issues.

Both issue lists are sorted by total number of comments. While not perfect, number of comments is a reasonable proxy for impact a given change will have.

### Pull Requests

The process described here has several goals:

- Maintain LVC's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible LVC
- Enable a sustainable system for LVC's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

**TO BE ADDED LATER**

While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional design work, tests, or other changes before your pull request can be ultimately accepted.

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
