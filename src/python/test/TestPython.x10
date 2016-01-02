import x10.io.Console;

import org.scalegraph.python.NativePython;
import org.scalegraph.python.NativePyObject;
import org.scalegraph.python.NativePyException;

class TestPython {

	public static def main(args :Rail[String]): void {
		Console.OUT.println("Hello, world");

		val test = new TestPython();
		test.run();
	}

	public def this() {
	}

	public def run() {
		test_importFile();
		test_runSimpleString();
		test_runString();
		test_dictLong();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();
		test_dictString();

		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();
		test_listNew();

		test_listFromRail();
		test_listFromRail();
		test_listFromRail();
		test_listFromRail();
		test_listAsRail();
		test_listAsRail();
		test_listAsRail();
		test_listAsRail();

		test_tupleNew();
		test_tupleNew();
		test_tupleNew();
		test_tupleFromRail();
		test_tupleFromRail();
		test_tupleFromRail();
		test_tupleAsRail();
		test_tupleAsRail();
		test_tupleAsRail();

		test_objectCallObjectFunc();
		test_objectCallObjectFunc();
		test_objectCallObjectFunc();
		test_objectCallObjectLambda();
		test_objectCallObjectLambda();
		test_objectCallObjectLambda();
		test_objectCallObjectLambdaPickled();
		test_objectCallObjectLambdaPickled();
		test_objectCallObjectLambdaPickled();
	}

	public def test_importFile() {
		Console.OUT.println("### test_importFile");
		val python = new NativePython();
		try {
			val po = python.importImport("multiply");
			python.calltest(po);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
	}

	public def test_runSimpleString() {
		Console.OUT.println("### test_runSimpleString");
		val python = new NativePython();
		python.runSimpleString("print('runSimpleString ok')");
		python.finalize();
		return true;
	}

	public def test_runString() {
		Console.OUT.println("### test_runString");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.runString("print('runString ok')", globals, locals);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_dictLong() {
		Console.OUT.println("### test_dictLong");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.dictSetItemString(locals, "multiplicand", python.longFromLong(123));
			python.dictSetItemString(locals, "multiplier", python.longFromLong(456));
			python.runString("result = multiplicand * multiplier", globals, locals);
			val result = python.longAsLong(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_dictString() {
		Console.OUT.println("### test_dictString");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.dictSetItemString(locals, "strleft", python.unicodeFromString("123"));
			python.dictSetItemString(locals, "strright", python.unicodeFromString("456"));
			python.runString("result = strleft + strright", globals, locals);
			val result = python.unicodeAsASCIIString(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_listNew() {
		Console.OUT.println("### test_listNew");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			val testlist = python.listNew(0);
			python.dictSetItemString(locals, "testlist", testlist);
			python.runString("result = str(testlist + [5, 4, 3, 2, 1])", globals, locals);
			val result = python.unicodeAsASCIIString(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_listFromRail() {
		Console.OUT.println("### test_listFromRail");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			val testrail = new Rail[NativePyObject](3);
			testrail(0) = python.longFromLong(111);
			testrail(1) = python.longFromLong(222);
			testrail(2) = python.longFromLong(333);
			val testlist = python.listFromRail(testrail);
			python.dictSetItemString(locals, "testlist", testlist);
			python.runString("result = str(testlist + [5, 4, 3, 2, 1])", globals, locals);
			val result = python.unicodeAsASCIIString(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_listAsRail() {
		Console.OUT.println("### test_listAsRail");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.runString("result = ['aaa', 'bbb', 'ccc']", globals, locals);
			val result = python.listAsRail(python.dictGetItemString(locals, "result"));
			for (i in result.range()) {
				Console.OUT.println("result(i) = " + python.unicodeAsASCIIString(result(i)));
			}
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_tupleNew() {
		Console.OUT.println("### test_tupleNew");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			val testtuple = python.tupleNew(0);
			python.dictSetItemString(locals, "testtuple", testtuple);
			python.runString("result = str(testtuple + (5, 4, 3, 2, 1))", globals, locals);
			val result = python.unicodeAsASCIIString(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_tupleFromRail() {
		Console.OUT.println("### test_tupleFromRail()");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			val testrail = new Rail[NativePyObject](3);
			testrail(0) = python.longFromLong(111);
			testrail(1) = python.longFromLong(222);
			testrail(2) = python.longFromLong(333);
			val testtuple = python.tupleFromRail(testrail);
			python.dictSetItemString(locals, "testtuple", testtuple);
			python.runString("result = str(testtuple + (5, 4, 3, 2, 1))", globals, locals);
			val result = python.unicodeAsASCIIString(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_tupleAsRail() {
		Console.OUT.println("### test_tupleAsRail()");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.runString("result = ('aaa', 'bbb', 'ccc')", globals, locals);
			val result = python.tupleAsRail(python.dictGetItemString(locals, "result"));
			for (i in result.range()) {
				Console.OUT.println("result(i) = " + python.unicodeAsASCIIString(result(i)));
			}
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_objectCallObjectFunc() {
		Console.OUT.println("### test_objectCallObjectFunc()");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.dictSetItemString(locals, "strleft", python.unicodeFromString("123"));
			python.dictSetItemString(locals, "strright", python.unicodeFromString("456"));
			python.runString("def testfunc(a, b):\n" +
							 "    return a + b\n",
							 globals, locals);
			val testrail = new Rail[NativePyObject](2);
			testrail(0) = python.dictGetItemString(locals, "strleft");
			testrail(1) = python.dictGetItemString(locals, "strright");
			val testcall = python.dictGetItemString(locals, "testfunc");
			val result = python.objectCallObject(testcall, testrail);
			val str_result = python.unicodeAsASCIIString(result);
			Console.OUT.println("result = " + str_result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_objectCallObjectLambda() {
		Console.OUT.println("### test_objectCallObjectLambda()");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.dictSetItemString(locals, "left", python.longFromLong(15));
			python.dictSetItemString(locals, "right", python.longFromLong(2));
			python.runString("testlambda = lambda a, b: a ** b", globals, locals);
			val testrail = new Rail[NativePyObject](2);
			testrail(0) = python.dictGetItemString(locals, "left");
			testrail(1) = python.dictGetItemString(locals, "right");
			val testcall = python.dictGetItemString(locals, "testlambda");
			val result = python.objectCallObject(testcall, testrail);
			val str_result = python.objectStr(result);
			Console.OUT.println("result = " + str_result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}

	public def test_objectCallObjectLambdaPickled() {
		Console.OUT.println("### test_objectCallObjectLambdaPickled()");
		val python = new NativePython();
		try {
			val main = python.importAddModule("__main__");
			val globals = python.moduleGetDict(main);
			val locals = python.dictNew();
			python.dictSetItemString(locals, "five", python.longFromLong(5));
			python.runString("import cloudpickle\n" +
							 "squared = lambda x: x ** 2\n" +
							 "pickled_lambda = cloudpickle.dumps(squared)",
							 globals, locals);
			python.runString("import pickle", globals, locals);
			python.runString("obj=pickle.loads(pickled_lambda)", globals, locals);
			python.runString("result=obj(five)", globals, locals);
			val str_result = python.objectStr(python.dictGetItemString(locals, "result"));
			Console.OUT.println("result = " + str_result);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Console.OUT.println("catched exception");
			Console.OUT.println(exception.strValue);
			Console.OUT.println(exception.strTraceback);
			exception.DECREF();
		}
		python.finalize();
		return true;
	}



}
