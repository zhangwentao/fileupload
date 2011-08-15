package com.renren.fileupload 
{
	/**
	 * 配置信息
	 * @author taowenzhang@gmail.com 
	 */
	public class Config
	{
		public static var maxUploadFileNum:int	//一次最大可上传的文件数
		public static var maxSingleFileSize:int	//单个上传文件的最大长度
		
		
		
		public static function getAllparamsName():Array
		{
			var paramsArray:Array = new Array();
			var varXmlList:XMLList = describeType(Config).variable;
			for each(var varXml:XML in varXmlList)
			{
				paramsArray.push(varXml.@name);
			}
			return paramsArray;
		}
	}
}