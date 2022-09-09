package apollo

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCompare(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name         string
		actualData   []byte
		expectedData []byte
		update       bool
		err          error
	}{
		{
			name:         "example",
			actualData:   []byte("abc"),
			expectedData: []byte("abc"),
			update:       true,
			err:          nil,
		},
		{
			name:         "example",
			actualData:   []byte("abc"),
			expectedData: []byte("abc"),
			update:       false,
			err:          &errFixtureNotFound{},
		},
		{
			name:         "example",
			actualData:   []byte("bc"),
			expectedData: []byte("abc"),
			update:       true,
			err:          &errFixtureMismatch{},
		},
		{
			name:         "nil",
			actualData:   nil,
			expectedData: nil,
			update:       true,
			err:          nil,
		},
	}

	a := New(t)

	for _, test := range tests {
		if test.update {
			err := a.Update(t, test.name, test.expectedData)
			assert.Nil(t, err)
		}

		err := a.compare(t, test.name, test.actualData)
		assert.IsType(t, test.err, err)

		a.GoldenFileName(t, test.name)
		err = os.RemoveAll(filepath.Dir(a.GoldenFileName(t, test.name)))
		assert.Nil(t, err)
	}
}

func TestCompareTemplate(t *testing.T) {
	data := struct {
		Name string
	}{
		Name: "example",
	}

	tests := []struct {
		name         string
		actualData   []byte
		expectedData []byte
		data         interface{}
		update       bool
		err          error
	}{
		{
			name:         "example",
			actualData:   []byte("abc example"),
			expectedData: []byte("abc {{ .Name }}"),
			data:         data,
			update:       true,
			err:          nil,
		},
		{
			name:         "example",
			actualData:   []byte("abc example"),
			expectedData: []byte("abc {{ .Name }}"),
			data:         nil,
			update:       false,
			err:          &errFixtureNotFound{},
		},
		{
			name:         "example",
			actualData:   []byte("bc example"),
			expectedData: []byte("abc {{ .Name }}"),
			data:         data,
			update:       true,
			err:          &errFixtureMismatch{},
		},
		{
			name:         "example",
			actualData:   []byte("bc example"),
			expectedData: []byte("abc {{ .Name }}"),
			data:         nil,
			update:       true,
			err:          &errMissingKey{},
		}}

	a := New(t)

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if test.update {
				err := a.Update(t, test.name, test.expectedData)
				assert.Nil(t, err)
			}

			err := a.compareTemplate(t, test.name, test.data, test.actualData)
			assert.IsType(t, test.err, err)

			err = os.RemoveAll(a.fixtureDir)
			assert.Nil(t, err)
		})
	}
}

func TestNormalizeLF(t *testing.T) {
	tests := map[string]struct {
		input     []byte
		expectedD []byte
	}{
		"windows style": {[]byte("Hello\r\nWorld"), []byte("Hello\nWorld")},
		"mac style":     {[]byte("Hello\rWorld"), []byte("Hello\nWorld")},
		"unix style":    {[]byte("Hello\nWorld"), []byte("Hello\nWorld")},
		"empty slice":   {[]byte(""), []byte{}},
		"nil input":     {nil, nil},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			assert.Equal(t, test.expectedD, normalizeLF(test.input))
		})
	}
}
