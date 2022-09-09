package apollo

import "os"

// WithFixtureDir sets the fixture directory.
//
// Defaults to `testdata`
func (a *Apollo) WithFixtureDir(dir string) error {
	a.fixtureDir = dir
	return nil
}

// WithNameSuffix sets the file suffix to be used for the golden file.
//
// Defaults to `.golden.txt`
func (a *Apollo) WithNameSuffix(suffix string) error {
	a.fileNameSuffix = suffix
	return nil
}

// WithFilePerms sets the file permissions on the golden files that are
// created.
//
// Defaults to 0644.
func (a *Apollo) WithFilePerms(mode os.FileMode) error {
	a.filePerms = mode
	return nil
}

// WithDirPerms sets the directory permissions for the directories in which the
// golden files are created.
//
// Defaults to 0755.
func (a *Apollo) WithDirPerms(mode os.FileMode) error {
	a.dirPerms = mode
	return nil
}

// WithDiffEngine sets the `diff` engine that will be used to generate the
// `diff` text.
func (a *Apollo) WithDiffEngine(engine DiffEngine) error {
	a.diffEngine = engine
	return nil
}

// WithDiffFn sets the `diff` engine to be a function that implements the
// DiffFn signature. This allows for any customized diff logic you would like
// to create.
func (a *Apollo) WithDiffFn(fn DiffFn) error {
	a.diffFn = fn
	return nil
}

// WithIgnoreTemplateErrors allows template processing to ignore any variables
// in the template that do not have corresponding data values passed in.
//
// Default value is false.
func (a *Apollo) WithIgnoreTemplateErrors(ignoreErrors bool) error {
	a.ignoreTemplateErrors = ignoreErrors
	return nil
}

// WithTestNameForDir will create a directory with the test's name in the
// fixture directory to store all the golden files.
//
// Default value is false.
func (a *Apollo) WithTestNameForDir(use bool) error {
	a.useTestNameForDir = use
	return nil
}

// WithSubTestNameForDir will create a directory with the sub test's name to
// store all the golden files. If WithTestNameForDir is enabled, it will be in
// the test name's directory. Otherwise, it will be in the fixture directory.
//
// Default value is false.
func (a *Apollo) WithSubTestNameForDir(use bool) error {
	a.useSubTestNameForDir = use
	return nil
}
