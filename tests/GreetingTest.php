<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../index.php';

class GreetingTest extends TestCase
{
    public function testGetGreetingReturnsHelloWorld()
    {
        $expected = "Hello World!";
        $actual = getGreeting();

        $this->assertEquals($expected, $actual);
    }
}