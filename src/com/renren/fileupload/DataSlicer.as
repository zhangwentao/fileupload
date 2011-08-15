package com.renren.fileupload 
{
	import flash.utils.ByteArray;
	
	/**
	 * 切割数据
	 * @author taowenzhang@gmail.com 
	 */
	class DataSlicer
	{
		public static var block_size_limit:uint;//数据切片大小上限(单位B)
		
		/**
		 * 将data切割成DataBlock,不修改原始数据
		 * @param	data	<ByteArray>	被切割的数据
		 * @return	<Array>	DataBlock数组
		 */
		public function slice(data:ByteArray):Array
		{
			var dataArr:Array = new Array();//存放切割后的数据块
			data.position = 0;
			while (data.bytesAvailable)
			{
				var byteArr:ByteArray = new ByteArray();
				
				if (data.bytesAvailable < block_size_limit * 3 / 2)
				{
					data.readBytes(byteArr, 0,data.bytesAvailable);
				}
				else
				{
					data.readBytes(byteArr, 0, block_size_limit);
				}
				dataArr.push(byteArr);
			}
			return dataArr;
		}
	}
}