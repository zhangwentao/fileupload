package com.renren.fileupload 
{
	import flash.net.FileReference;
	/**
	 * 文件
	 * @author taowenzhang@gmail.com 
	 */
	public class FileItem
	{
		public static var FILE_STATUS_QUEUED:int 		= -1;//已加入上传队列
		public static var FILE_STATUS_IN_PROGRESS:int	= -2;//正在上传
		public static var FILE_STATUS_ERROR:int			= -3;//发生错误
		public static var FILE_STATUS_SUCCESS:int		= -4;//上传完毕
		public static var FILE_STATUS_CANCELLED:int		= -5;//已取消
		
		public static var id_prefix:String = '';		//id前缀
		
		public var id:String;	//编号
		public var status:int;	//状态
		public var fileReference:FileReference;//文件引用
		
		
		private static var file_id_sequence:uint = 0;	//id增量
		
		
		/**
		 * 
		 * @param	fileReference	<FileReference> 文件引用
		 */
		public function FileItem(fileReference:FileReference) 
		{
			this.id = id_prefix + "_" + file_id_sequence++;
			this.fileReference = fileReference;
		}
		
		/**
		 * 获取文件信息
		 * @return	<Object>
		 */
		public function getInfoObject():Object
		{
			var info:Object = {
				id:this.id,
				name:this.fileReference.name,
				size:this.fileReference.size,
				type:this.fileReference.type
			}
			return info;
		}
	}
}