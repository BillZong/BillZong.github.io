---
title: Practical TDD in Go
author: Bill Zong
tags:
  - golang
  - TDD
categories:
  - Golang
abbrlink: 37e0e416
date: 2021-04-12 22:32:00
---
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Abstract](#abstract)

- [Abstract](#abstract)
- [Introduction](#introduction)
- [Premilinaries](#premilinaries)
- [The Three TDD Laws](#the-three-tdd-laws)
- [Test-Driven Development](#test-driven-development)
    - [Tools](#tools)
    - [Practice](#practice)
        - [Basic TDD](#basic-tdd)
        - [Show Code Coverage](#show-code-coverage)
        - [What if we write some race condition codes/tests?](#what-if-we-write-some-race-condition-codestests)
- [Mocking](#mocking)
    - [Effectiveness](#effectiveness)
    - [Isn't mocking evil?](#isnt-mocking-evil)
- [reference](#reference)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Abstract

This Paragraph is all about TDD(Test-Driven Development) in Go.

We introduce the basic raws in TDD; introduce some usful tools in Go; show one practice using TDD. And we discuss the mocking in the final chapter.

## Introduction

This paragraph suppose that you are familiar with Go, and have already heard about TDD before.

* For those ones who hadn't heard about TDD, read [this wiki](https://en.wikipedia.org/wiki/Test-driven_development) first.
* If you have already used TDD in Go before, all you need is reviewing ["The Three TDD Laws"](), and [the discussion on mocking]().
* If you're an expert on TDD, skip this paragraph as you wish.

## Premilinaries

TDD is an exellent revolution on coding practice. Everyone should try it, no matter you like it or not.

The "red/green/refactor" mandra makes you focusing on actual behavior of codes. That means your codes are easier to test, easier to refactor, and more robust.

The first thing you need to do with TDD is to break down your programmer's conventional thinking. You have to think as a user and a programmer, when you're in different coding stage.

* You are a user when you are writing tests.
* You are a programmer when you are writing codes.

There are lots of helpful details about TDD. Such as "Test structure", "Best practices", "Anti-patterns", "Limitations". For more details on those topic, read [this wiki](https://en.wikipedia.org/wiki/Test-driven_development)

## The Three TDD Laws

Although there are lots of rules to compiliance, the basic laws can be briefly described as the following three:

1. You are not allowed to write any production code unless it is to make a failing unit test pass.
2. You are not allowed to write any more of a unit test than is sufficient to fail; and compilation failures are failures.
3. You are not allowed to write any more production code than is sufficient to pass the one failing unit test.

There is another easier saying:

1. Starting with a test forces you to think about the intended behavior;
2. Writing code based on a test forces you to write testable code;
3. Immediately refactoring the result forces you to think about your code and how it fits in the larger picture.

## Test-Driven Development

### Tools

* VSCode
    * **IDE** we use in this paragragh.
* VSCode plugins
    * `Go` by *Microsoft*.
        * It's full of commands using other go tools.
        * It provides the code coverage highlight.
        * It formats go files automacicly when you save any files.
    * `Golang TDD` by *joaoacdias*.
        * It will run the current package's tests when you save a file or a test file. The result is showing on the status bar immediately when the tests finished.
        * It runs tests in parallel. That means, when your tests are in race condition, they would be **"sometimes failing"** status.

### Practice

***"Talk is cheap, show me the data and images."***

#### Basic TDD

* Enable the `Golang TDD`.
    ![001](https://lexiangla.com/assets/8c9cdf96164611e9b440525400ac2e73 "001")
    * Enabled
        ![002](https://lexiangla.com/assets/ae070e72164611e996f05254004f9daa)

* Create/Open any test file, and write some tests, save it.
    ![003](https://lexiangla.com/assets/b758040e164611e98bb452540089e328 "003")
    * Fail
        ![004](https://lexiangla.com/assets/bf6db67a164611e991e8525400a20cd4 "004")

* Write some codes to make test pass, save it.
    ![005](https://lexiangla.com/assets/ccf53016164611e9aedf5254002ec14d "005")
    * Success
        ![006](https://lexiangla.com/assets/d1e15e24164611e986885254004f9daa "006")

* Write more tests.
* Write more codes, do some refactor work if necessary.
* And so on...

#### Show Code Coverage

* When we pass the tests, we could highlight codes haved been covered.

![007](https://lexiangla.com/assets/dc09c166164611e99a0f525400b4d70f "007")

* The results:

![008](https://lexiangla.com/assets/e29f0086164611e9b89d525400dca728 "008")

* Rerun the toggle command to disabled highlight.

#### What if we write some race condition codes/tests?

* We got the green failing status.

![009](https://lexiangla.com/assets/ea1e8c6e164611e9954c525400177fdc "009")

## Mocking

**Mock**: A mock is specified by an individual test case to validate test-specific behavior, checking parameter values and call sequencing.

### Effectiveness

1. Help the test process by always returning the same, realistic data that tests can rely upon.
2. Can be set into predefined fault modes so that error-handling routines can be developed and reliably tested.
3. Help the test focusing on interface, make the structure design more  modular.
4. Take less time to test. Reply a service in mocking would take milliseconds. At the same time, it might take seconds in actual world.

### Isn't mocking evil?

Yes, sometimes. Especially when you're just numbly coding tests, and won't do any refactor work.

It is sign that you should think about the design or refactor your codes:

1. The thing you are testing is having to do too many things.
    * Break the module apart so it does less.
2. Its dependencies are too fine-grained.
    * Think about how you can consolidate some of these dependencies into one meaningful module.
3. Your test is too concerned with implementation details.
    * Favour testing expected behaviour rather than the implementation.

The basic resolution:

1. Make right abstraction.
2. Stop testing private functions.
3. Mocking should not know too much about your implementation details.

## reference

1. [Test-driven development](https://en.wikipedia.org/wiki/Test-driven_development)
2. [Test-Driven Development in Go](https://medium.com/@pierreprinetti/test-driven-development-in-go-baeab5adb468)
3. [Dependency Injection](https://github.com/quii/learn-go-with-tests/blob/master/dependency-injection.md)
4. [Mocking](https://github.com/quii/learn-go-with-tests/blob/master/mocking.md)
5. [Test-driven development with Go](https://leanpub.com/golang-tdd/read)