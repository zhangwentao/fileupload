package com.renren.fileupload 
{
	import com.renren.picUpload.events.DBUploaderEvent;
	import com.renren.util.net.ByteArrayUploader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;
	
	/**
	 * 上传 DataBlock 至服务器
	 * @author taowenzhang@gmail.com
	 */
	class DataBlockUploader extends EventDispatcher
	{
		//eg:"http://upload.renren.com/upload.fcgi?pagetype=addflash&hostid=200208111"
		public static var upload_url:String;	
		
		public var response:*;					//服务器返回的数据
		
		private var uploader:ByteArrayUploader;	//用于上传二进制数据	
		private var dataBlock:DataBlock;		//上传的数据块
				
		/**
		 * 上传dataBlock
		 * @param	dataBlock 
		 */
		public function upload(dataBlock:DataBlock):void
		{
			this.dataBlock = dataBlock;
			
			initUploader();
			initReqVariables();
			dataBlock.file.status = FileItem.FILE_STATUS_IN_PROGRESS;//设置图片状态为:正在上传
			uploader.upLoad(dataBlock.data);
		}
		
		/**
		 * 初始化uploader
		 */
		private function initUploader():void
		{
			uploader= new ByteArrayUploader();
			uploader.url = upload_url;		  //上传cgiurl
			uploader.addEventListener(IOErrorEvent.IO_ERROR, handle_ioError);
			uploader.addEventListener(Event.COMPLETE, handle_upload_complete);
		}
		
		/**
		 * 初始化请求参数
		 */
		private function initReqVariables():void
		{
			var urlVar:Object = uploader.urlVariables;//获取uploader的参数对象
			
			//-----设置请求参数-----//
			urlVar["block_index"] = dataBlock.index;
			urlVar["block_count"] = dataBlock.count;
			urlVar["uploadid"] = dataBlock.file.id;
		}

		/**
		 * 处理ioError
		 * @param	evt		<ioErrorEvent>	
		 */
		private function handle_ioError(evt:IOErrorEvent):void
		{
			//TODO:处理IOError错误
			dispatchEvent(evt);
		}
		
		/**
		 * 上传完毕服务器返回数据后调用
		 * @param	evt		<Event>
		 */
		private function handle_upload_complete(evt:Event):void
		{
			response = evt.target.data;
			//TODO:根据服务器返回的信息做出相应的处理
		}
	}
}